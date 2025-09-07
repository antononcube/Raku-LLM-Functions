use v6.d;

use JSON::Fast;

#===========================================================
# Sub info extraction
#===========================================================

#| Function to extract sub info into a hashmap.
#| C<&sub> -- a callable.
our sub sub-info(&sub --> Hash) is export {
    my %sub-info;

    # Get subroutine signature and name
    my $sub-name = &sub.name;
    my $signature = &sub.signature;

    # Store sub name and arguments
    %sub-info{'name'} = $sub-name;
    %sub-info{'returns'} = $signature.returns.gist;
    %sub-info{'arity'} = $signature.arity;
    %sub-info{'count'} = $signature.count;

    # Get sub description from pod documentation
    %sub-info{'description'} = do if &sub.WHY {
        my $res = &sub.WHY.leading ?? &sub.WHY.leading.Str.trim !! '';
        $res ~= &sub.WHY.trailing ?? ' ' ~ &sub.WHY.trailing.Str.trim !! '';
        $res.trim
    } else {
        "No description available";
    }

    # Get arguments/parameters info
    my @required;
    %sub-info{'parameters'} =
            do for $signature.params.kv -> $i, $param {
                my $name = $param.name;
                my $type = $param.type;
                my $position = $i;
                my $named = $param.named;
                my $slurpy = $param.slurpy;
                my $optional = $param.optional;
                my $default = $param.default ~~ Callable:D ?? $param.default.() !! Nil;
                without $default { @required.push($name) }
                my $description = do if $param.WHY {
                    my $res = $param.WHY.leading ?? $param.WHY.leading.Str.trim !! '';
                    $res ~= $param.WHY.trailing ?? ' ' ~ $param.WHY.trailing.Str.trim !! '';
                    $res.trim
                } else {
                    ''
                }
                {:$name, :$type, :$position, :$named, :$default, :$optional, :$slurpy, :$description}
            }

    %sub-info<required> = @required;

    return %sub-info;
}

#===========================================================
# LLM function calling definition
#===========================================================
#| Make LLM tool (function calling) definitions.
proto sub llm-tool-definition(|) is export {*}

multi sub llm-tool-definition(&sub, Str:D :$format = 'json') {
    return llm-tool-definition(sub-info(&sub), :$format);
}

multi sub llm-tool-definition(@subs where @subs.all ~~ Callable:D, Str:D :$format = 'json') {
    return llm-tool-definition(@subs.map({ sub-info($_) }), :$format);
}

multi sub llm-tool-definition(%info, Str:D :$format = 'json') {
    my %parameters;
    my %properties;
    my @required;

    my @paramSpecs = do if %info<parameters> ~~ Map:D {
        %info<parameters>.map({ [|$_.value, name => $_.key] })».Hash
    } else {
       |%info<parameters>
    }

    %properties = do for @paramSpecs -> %r {
        die 'The argument spec has no name.' unless %r<name>:exists;
        die "The argument spec for {%r<name>} has no type." unless %r<type>:exists;

        my $type = do given %r<type> {
            when $_ ~~ Str:D && $_.lc ∈ <number integer string> { $_.lc }
            when Int | UInt { 'integer' }
            when Num | Numeric { 'number' }
            when Str { 'string' }
            when !$_.defined {
                note "Undefined type of parameter ⎡{%r<name>}⎦; continue assuming it is a string.";
                'string'
            }
            default {
                die 'Do not know how to represent argument type in JSON schema.'
            }
        }

        my %schema = :$type, description => %r<description>;
        if %r<enum> { %schema<enum> = %r<enum> }
        if !%r<named> && !%r<default>.defined { @required.push(%r<name>) }
        %r<name> => %schema
    }

    %parameters<type> = 'object';
    %parameters<properties> = %properties;
    if %properties {
        if @required { %parameters<required> = @required }
        if strict => %info<strict> // True {
            %parameters<additionalProperties> = False
        }
    }

    return llm-tool-definition(
            name => %info<name>,
            description => %info<description> // '',
            :%parameters,
            strict => %info<strict> // True,
            type => %info<type> // 'function',
            :$format);
}

multi sub llm-tool-definition(@infos where @infos.all ~~ Map:D, Str:D :$format = 'json') {
    return @infos.map({ llm-tool-definition($_, :$format) });
}

multi sub llm-tool-definition(
        Str:D :$name!,
        Str:D :$description = '',
        :%parameters = Empty,
        Bool:D :$strict = True,
        Str:D :$type = 'function',
        Str:D :$format = 'json'
                              ) {

    my %res =
            :$type,
            function => {
                :$type,
                :$name,
                :$description,
                :%parameters,
                :$strict
            };

    return $format.lc eq 'json' ?? to-json(%res) !! %res;
}

#===========================================================
# LLM Tool
#===========================================================

sub validate-sub-info(%info) {
    my $shapeCheck =
            (%info.keys (&) <name description parameters required>).elems == 4
            && %info<parameters> ~~ Map:D
            && %info<parameters>.values.all ~~ Map:D;

    my $knownRequired = (%info<required> (-) %info<parameters>.keys).elems == 0;

    return $shapeCheck && $knownRequired;
}

class LLM::Tool {
    has %.info is required;
    has &.function is required;
    has $.json-spec = Whatever;

    submethod BUILD(:%!info, :&!function, :$!json-spec = Whatever) {
        die 'Defined function is expected. (Not a just a Callable type.)'
        unless &!function ~~ Callable:D;

        die 'The %info argument does not have expected structure.'
        unless validate-sub-info(%!info);
    }

    multi method new(Str:D $json-spec, &function) {
        my $info = try from-json($json-spec);
        if $! {
            die 'The argument :$spec is expected to be a valid JSON string.'
        }

        # Further validation
        die 'The argument :$json-spec is expected to be a JSON dictionary with keys "type" and "function".'
        unless $info ~~ Map:D && ($info<type>:exists) && ($info<function>:exists);

        my %info = $info<function>;
        self.bless(:%info, :&function, :$json-spec);
    }

    multi method new(%info, &function) {
        my $json-spec = llm-tool-definition(%info, format => 'json');
        self.bless(:%info, :&function, :$json-spec)
    }

    multi method new(Whatever, &function) {
        my %info = sub-info(&function);
        %info<parameters> = (%info<parameters>.map(*<name>).Array Z=> %info<parameters>.Array).Hash;
        my $json-spec = llm-tool-definition(&function, format => 'json');
        self.bless(:%info, :&function, :$json-spec)
    }

    multi method new(&func) {
        self.new(Whatever, &func)
    }

    #--------------------------------------------------------
    #| To Hash
    multi method Hash(::?CLASS:D:-->Hash) {
        return %(:%!info, :&!function);
    }

    #| To string
    multi method Str(::?CLASS:D:-->Str) {
        return self.gist;
    }

    #| To gist
    multi method gist(::?CLASS:D:-->Str) {
        return "LLMTool({self.info<name>}, {self.info<description>})";
    }
}

#===========================================================
# LLM Tool Request
#===========================================================

class LLM::ToolRequest {
    has $.id = Whatever;
    has Str:D $.tool is required;
    has %.params is required;
    has Str:D $.request = '';

    #--------------------------------------------------------
    submethod BUILD(Str:D :$!tool, :%!params, Str:D :$!request = '', :$!id = Whatever) {}

    multi method new(Str:D :name(:$tool), :args(:%params), Str:D :$request = '', :$id = Whatever) {
        self.bless(:$tool, :%params, :$request, :$id)
    }

    multi method new(Str:D $tool, %params, Str:D $request = '', $id = Whatever) {
        self.bless(:$tool, :%params, :$request, :$id)
    }

    #--------------------------------------------------------
    #| To Hash
    multi method Hash(::?CLASS:D:-->Hash) {
        return %(:$!tool, :%!params, :$!request);
    }

    #| To string
    multi method Str(::?CLASS:D:-->Str) {
        return self.gist;
    }

    #| To gist
    multi method gist(::?CLASS:D:-->Str) {
        return "LLMToolRequest({self.tool}, {self.params.map({ ":{$_.key}({$_.value.gist})" }).join(', ')}, :id({self.id.raku}))";
    }
}

#===========================================================
# LLM Tool Response
#===========================================================

class LLM::ToolResponse {
    has Str:D $.tool is required;
    has %.params is required;
    has LLM::ToolRequest $.request is required;
    has $.output = Whatever;
    # has $.response-string = '';

    #--------------------------------------------------------
    submethod BUILD(:$!tool, :%!params, :$!request, :$!output = Whatever) {}

    multi method new($tool, %params, $request, $output = Whatever) {
        self.bless(:$tool, :%params, :$request, :$output)
    }

    multi method new(:t(:$tool), :p(:parameters(:%params)), :r(:$request), :o(:$output) = Whatever) {
        self.bless(:$tool, :%params, :$request, :$output)
    }

    #--------------------------------------------------------
    #| To Hash
    multi method Hash(::?CLASS:D:-->Hash) {
        return %(:$!tool, :%!params, :$!request, :$!output);
    }

    multi method Hash(::?CLASS:D: $format is copy = Whatever-->Hash) {

        if $format.isa(Whatever) { $format = 'raku'}
        die 'The first argument is expected to be a string or Whatever.'
        unless $format ~~ Str:D;

        return do given $format.lc {
            when $_ (elem) <hash raku> { %(:$!tool, :%!params, :$!request, :$!output) }
            when $_ (elem) <openai chatgpt> { %(role => 'tool', content => $!output, tool_call_id => $!request.id // '') }
            when $_ eq 'gemini' { %(functionResponse => %('name' => $!tool, response => %( content => $!output))) }
            default {
                note 'Unknown format. The implemented formats are "OpenAI", "Gemini", "Raku", and Whatever. Continuing with Whatever.';
                self.Hash(Whatever)
            }
        }
    }

    #| To string
    multi method Str(::?CLASS:D:-->Str) {
        return self.gist;
    }

    #| To gist
    multi method gist(::?CLASS:D:-->Str) {
        return "LLMToolResponse({self.tool}, {self.request.params.map({ ":{$_.key}({$_.value.gist})" }).join(', ')}, :output({self.output.gist}))";
    }
}

#===========================================================
# Generate LLM tool response
#===========================================================

#| Generate answers for request by a list of tools.
proto sub generate-llm-tool-response($tool, $request) is export {*}
multi sub generate-llm-tool-response(LLM::Tool:D $tool, LLM::ToolRequest:D $request) {
    generate-llm-tool-response([$tool,], $request)
}

multi sub generate-llm-tool-response(@tools, LLM::ToolRequest:D $request) {
    die 'The first argument is expected to be an LLM::Tool object or a list of such objects.'
    unless @tools.all ~~ LLM::Tool:D;

    # Scan the tools that apply to the request.
    my $tool = try @tools.grep({ $_.info<name> eq $request.tool }).head;

    # Give errors for non-existent tools.
    if $! {
        # Is ad hoc failure instead of just using die
        my %result =
                request => $request.gist,
                llm-tools => @tools».gist,
                error => "No tool with name { $request.tool } found from tool list.";
        fail %result;
    }

    # Fill-in the parameter values for the applicable tools and evaluate the tool functions.
    my %args = |$tool.info<parameters>;

#    note (:%args);
#    note ('$request.params' => $request.params);
#    note %args<required>;
#    note (required => $request.params{|%args<required>});
    # TODO:
    # 1. [X] Make sure the required arguments are filled in or give error.
    # 2. [X] Fill in the positional arguments and the named arguments.
    # 3. [ ] Pass non-required positional arguments in the correct order
    # 4. [ ] Check the type of the values given in the request object.
    my @reqArgs = $request.params{|$tool.info<required>};

    # Verify required arguments
    if @reqArgs.elems < $tool.info<required>.elems {
        my %result =
                required => $tool.info<required>,
                llm-tools => $tool.gist,
                error => "Not enough required argument values are supplied.";
        fail %result;
    }

    # Positional and named arguments
    my @posArgs;
    my %namedArgs;
    for $request.params.kv -> $k, $r {
        if !%args{$k}<named> && !%args{$k}<default>.defined && $k ∉ $tool.info<required> { @posArgs.push($r) }
        if %args{$k}<named> { %namedArgs{$k.subst(/ ^ <[$%@]> /)} = $r}
    }

    # Passing positional arguments with non-default values is complicated.
    #say [|@reqArgs, |@posArgs, |%namedArgs].raku;
    my $output = $tool.function.(|@reqArgs, |%namedArgs);

    # Return LLM::ToolResponse object.
    return LLM::ToolResponse.new(tool => $request.tool, params => %args, :$request, :$output)
}

#===========================================================
# Make LLM tool requests
#===========================================================
# This is very OpenAI protocol "inspired".
proto sub llm-tool-requests($resp) is export {*}

multi sub llm-tool-requests(Str:D $resp) {
    my $spec = try from-json($resp);
    if $! {
        die 'Cannot convert JSON string.'
    }
    return llm-tool-requests($spec);
}

multi sub llm-tool-requests(@resp) {
    if @resp.all ~~ Map:D {
        return llm-tool-requests(@resp.head)
    } else {
        die 'A JSON string, a hashmap, or an array of hashmaps is expected as a first argument.'
    }
}

multi sub llm-tool-requests(%resp) {
    my @toolCalls;
    if (%resp<finish_reason> // 'unknown') eq 'tool_calls' {
        @toolCalls = |%resp<message><tool_calls>
    }

    die 'Unknown structure of tool calls.'
    unless @toolCalls.all ~~ Map:D;

    my @toolReqs = do for @toolCalls -> %spec {
       LLM::ToolRequest.new(
                tool => %spec<function><name>,
                params => from-json(%spec<function><arguments>),
                id => %spec<id> // Whatever
                )
    }

    return @toolReqs;
}