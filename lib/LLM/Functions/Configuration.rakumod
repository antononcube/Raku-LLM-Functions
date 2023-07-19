use v6.d;

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

    # "Model" base model
    has Str $.model is rw;

    # "Query function
    has &.function is rw = WhateverCode;

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

    # "StopTokens" tokens on which to stop generation
    has @.stop-tokens = <. ? !>;

    # "Tools" list of LLMTool objects to make available
    has @.tools;

    # "ToolPrompt" prompt specifying tool format
    has $.tool-prompt = '';

    # "ToolRequestParser" function for parsing tool requests
    has &.tool-request-parser = WhateverCode;

    # "ToolResponseInsertionFunction" function for serializing tool responses
    has &.tool-response-insertion-function = WhateverCode;

    # Argument remaps
    has %.argument-renames;

    # Evaluator object
    has $.evaluator is rw = Whatever;

    #--------------------------------------------------------
    #| To Hash
    method Hash(-->Hash) {
        return
                { :$!name,
                  :$!api-key, :$!api-user-id,
                  :$!module, :$!model, :&!function,
                  :$!temperature, :$!total-probability-cutoff, :$!max-tokens,
                  :$!format,
                  :@!prompts, :$!prompt-delimiter,
                  :@!stop-tokens,
                  :@!tools, :$!tool-prompt, :&!tool-request-parser, :&!tool-response-insertion-function,
                  :$.evaluator
                };
    }

    #| To string
    method Str(-->Str) {
        return self.gist;
    }

    #| To gist
    method gist(-->Str) {
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