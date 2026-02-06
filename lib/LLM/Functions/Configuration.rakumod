# Merges the designs of:
#   https://resources.wolframcloud.com/PacletRepository/resources/Wolfram/LLMFunctions/ref/LLMConfiguration.html
# and
#   https://github.com/antononcube/Raku-ML-FindTextualAnswer/blob/main/lib/ML/FindTextualAnswer/LLM/TextualAnswer.rakumod

# Instead of a class this can be just a Hash object.
# But it seems easier to "just" have a class.

#class LLM::Functions::Evaluator {!!!}

class LLM::Functions::Configuration {

    # Name
    has Str $.name;

    # API key
    has $.api-key = Whatever;

    # API user ID
    has $.api-user-id = Whatever;

    # LLM module (to load for access)
    has Str $.module;

    # Base URL
    has Str $.base-url is rw = '';

    # Path
    has $.path is rw = Whatever;

    # "Model" base model
    has Str $.model is rw;

    # "Query" function
    has &.function is rw = WhateverCode;

    # Embedding Model
    has Str $.embedding-model is rw;

    # "Embedding" function
    has &.embedding-function is rw = WhateverCode;

    # "Temperature" sampling temperature
    has Numeric $.temperature = 0;

    # "TotalProbabilityCutoff" #sampling probability cutoff (nucleus sampling)
    has Numeric $.total-probability-cutoff = 0;

    # Max output tokens
    has UInt $.max-tokens = 64;

    # Format for the output
    # (This might "overlap" functionality-wise with the tool-* parameters below.)
    has $.format = Whatever;

    # "Prompts" initial prompts
    has @.prompts;

    # "PromptDelimiter" string to insert between prompts
    has $.prompt-delimiter = ' ';

    # "Examples" initial prompts
    has @.examples;

    # "StopTokens" tokens on which to stop generation
    has @.stop-tokens = <. ? !>;

    # "Tools" list of LLMTool objects to make available
    has @.tools;

    # Tool configuration
    has %.tool-config;

    # "ToolPrompt" prompt specifying tool format
    has $.tool-prompt = '';

    # "ToolRequestParser" function for parsing tool requests
    has &.tool-request-parser = WhateverCode;

    # "ToolResponseInsertionFunction" function for serializing tool responses
    has &.tool-response-insertion-function = WhateverCode;

    # List of images URLs, file names, or Base64 strings
    has @.images;

    # Reasoning effort gpt-5* models
    has $.reasoning-effort = Whatever;

    # Verbosity is a new argument for gpt-5* models
    has $.verbosity = Whatever;

    # Argument remaps
    # Re-naming into arguments known by the LLM function &!function .
    has %.argument-renames;

    # Evaluator object
    has $.evaluator is rw = Whatever;

    #--------------------------------------------------------
    method clone {
        nextwith
                :prompts(@!prompts.clone),
                :stop-tokens(@!stop-tokens.clone),
                :tools(@!tools.clone),
                :images(@!images.clone),
                :argument-renames(%!argument-renames.clone),
                |%_
    }

    #--------------------------------------------------------
    #| Gives the known params of the LLM access function.
    #| Like &OpenAITextCompletion or &GeminiGenerateContent.
    method known-params() {
        # Find known parameters
        my @knownParamNames = self.function.candidates.map({ $_.signature.params.map({ $_.usage-name }) }).flat;
        return @knownParamNames
    }

    #| Modifies the hashmap of named arguments by using
    #| the known params of the LLM access function and removing (excluding)
    #| specified parameter names.
    proto method normalize-params(%args, |) {*}
    multi method normalize-params(%args, @exclude = ['prompts', ]) {
        self.normalize-params(%args, :@exclude)
    }

    multi method normalize-params(%args, :@exclude = ['prompts', ]) {
        # Find known parameters
        my @knownParamNames = self.known-params();

        # Make all named parameters hash
        my %args2 = self.Hash , %args;

        # Handling the argument renaming in a more bureaucratic manner
        for self.argument-renames.kv -> $k, $v {
            %args2{$v} = %args2{$v} // %args2{$k} // Whatever;
        }

        %args2 = %args2.grep({ $_.key ∉ @exclude && $_.key ∈ @knownParamNames }).Hash;

        return %args2;
    }

    #--------------------------------------------------------
    #| To Hash
    multi method Hash(::?CLASS:D:-->Hash) {
        my %res =
                :$!name,
                :$!api-key, :$!api-user-id,
                :$!module, :$!base-url, :$!model, :&!function, :$!embedding-model, :&!embedding-function,
                :$!temperature, :$!total-probability-cutoff, :$!max-tokens,
                :$!reasoning-effort, :$!verbosity,
                :$!format,
                :@!prompts, :$!prompt-delimiter,
                :@!examples,
                :@!stop-tokens,
                :@!tools, :$!tool-prompt, :&!tool-request-parser, :&!tool-response-insertion-function,
                :@!images,
                :%.argument-renames,
                :$.evaluator
                ;
        # $!path is a Whatever it is not added:
        # - The $path argument in the "WWW::*" packages is defined as a string with a certain default value.
        # - Configurations are turned into hashmaps in the evaluator object
        with $!path { %res = %res , {:$!path} }
        return %res;
    }

    #| To string
    multi method Str(::?CLASS:D:-->Str) {
        return self.Hash.map( -> $p {
            given $p.value {
                when Whatever { $p.key => 'Whatever'}
                when WhateverCode { $p.key => 'WhateverCode'}
                when Callable { $p.key => $_.name }
                default { $p.key => $_.Str }
            }
        }).Str;
    }

    #| To gist
    multi method gist(::?CLASS:D:-->Str) {
        my @ks = <name model module max-tokens>;
        my @vals = @ks Z=> self.Hash{@ks};
        if @!prompts { @vals .= push((prompts-count => @!prompts.elems)) }
        if @!examples { @vals .= push((examples-count => @!examples.elems)) }
        return 'LLM::Configuration' ~ @vals.List.raku;
    }
}