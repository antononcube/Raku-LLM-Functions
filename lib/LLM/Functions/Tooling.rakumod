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

    # Get argument descriptions
    %sub-info{'arguments'} =
            do for $signature.params -> $param {
                my $name = $param.name;
                my $type = $param.type;
                my $named = $param.named;
                my $default = $param.default ~~ Callable:D ?? $param.default.() !! Nil;
                my $description = do if $param.WHY {
                    my $res = $param.WHY.leading ?? $param.WHY.leading.Str.trim !! '';
                    $res ~= $param.WHY.trailing ?? ' ' ~ $param.WHY.trailing.Str.trim !! '';
                    $res.trim
                } else {
                    ''
                }
                {:$name, :$type, :$named, :$default, :$description}
            }

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
    my @required;

    %parameters = do for |%info<arguments> -> %r {

        die 'The arugment spec has no type' unless %r<type>:exists;

        my $type = do given %r<type> {
            when Num | Numeric { 'number' }
            when Int | UInt { 'integer' }
            when Str { 'string' }
            default {
                die 'Do not know how to represent argument type in JSON schema.'
            }
        }

        my %schema = :$type, description => %r<description>;
        if %r<enum> { %schema<enum> = %r<enum> }
        if !%r<named> && !%r<default>.defined { @required.push(%r<name>) }
        %r<name> => %schema
    }

    if %parameters {
        %parameters<type> = 'object';
        if @required { %parameters<required> = @required }
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

class LLM::Tool {
    has Str:D $.spec = '';
    has &.function is required;

    multi method new(Str:D :s(:$!spec), :f(:&!function)) {
        my $jsonSpec = try from-json($!spec);
        if $! {
            die 'The argument :$spec is expected to be a valid JSON string.'
        }

        # Further validation
        die 'The argument :$spec is expected to be JSON dictionary with keys "type" and "function".'
        unless $jsonSpec ~~ Map:D && ($jsonSpec<type>:exists) && ($jsonSpec<function>:exists);
    }

    multi method new(Map:D :s(:%spec), Callable:D :f(:&function)) {
        my $spec = llm-tool-definition(%spec, format => 'json');
        self.new(:$spec, :&function)
    }

    multi method new(Callable:D :f(:&function)) {
        my $spec = llm-tool-definition(&function);
        self.new(:$spec, :&function)
    }

    multi method new(Callable:D &func) {
        self.new(function => &func)
    }

    #--------------------------------------------------------
    #| To Hash
    multi method Hash(::?CLASS:D:-->Hash) {
        return %(:$!spec, :&!function);
    }

    #| To string
    multi method Str(::?CLASS:D:-->Str) {
        return self.gist;
    }

    #| To gist
    multi method gist(::?CLASS:D:-->Str) {
        return self.Hash.gist;
    }
}

#===========================================================
# LLM Tool Request
#===========================================================

class LLM::ToolRequest {
    has Str:D $.tool is required;
    has %.params is required;
    has Str:D $.request = '';

    #--------------------------------------------------------
    multi method new(:t(:$!tool), :p(:parameters(:%!params)), :r(:$!request) = '') {}

    multi method new($tool, %params, $request = '') {
        self.new(:$tool, :%params, :$request)
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
        return self.Hash.gist;
    }
}

#===========================================================
# LLM Tool Response
#===========================================================

class LLM::ToolResponse {
    has Str:D $.tool is required;
    has %.params is required;
    has LLM::ToolRequest $.request is required;

    #--------------------------------------------------------
    multi method new(:t(:$!tool), :p(:parameters(:%!params)), :r(:$!request)) {}

    multi method new($tool, %params, $request) {
        self.new(:$tool, :%params, :$request)
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
        return self.Hash.gist;
    }
}
