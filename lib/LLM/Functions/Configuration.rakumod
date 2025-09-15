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
    method normalize-params(%args, @exclude = ['prompts', ]) {
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
        return
                { :$!name,
                  :$!api-key, :$!api-user-id,
                  :$!module, :$!base-url, :$!model, :&!function, :$!embedding-model, :&!embedding-function,
                  :$!temperature, :$!total-probability-cutoff, :$!max-tokens,
                  :$!format,
                  :@!prompts, :$!prompt-delimiter,
                  :@!examples,
                  :@!stop-tokens,
                  :@!tools, :$!tool-prompt, :&!tool-request-parser, :&!tool-response-insertion-function,
                  :@!images,
                  :%.argument-renames,
                  :$.evaluator
                };
    }

    #| To string
    multi method Str(::?CLASS:D:-->Str) {
        return self.gist;
    }

    #| To gist
    multi method gist(::?CLASS:D:-->Str) {
        return self.Hash.map( -> $p {
            given $p.value {
                when Whatever { $p.key => 'Whatever'}
                when WhateverCode { $p.key => 'WhateverCode'}
                when Callable { $p.key => $_.name }
                default { $p.key => $_.Str }
            }
        }).Str;
    }
}