use v6.d;

use JSON::Fast;
use Hash::Merge;

use WWW::OpenAI;
use WWW::OpenAI::TextCompletions;
use WWW::OpenAI::ChatCompletions;

use WWW::PaLM;
use WWW::PaLM::GenerateText;
use WWW::PaLM::GenerateMessage;

use LLM::Functions::Chat;
use LLM::Functions::Configuration;
use LLM::Functions::Evaluator;
use LLM::Functions::EvaluatorChat;
use LLM::Functions::EvaluatorChatPaLM;

unit module LLM::Functions;

#===========================================================
# Utility
#===========================================================

multi reallyflat(+@list) {
    gather @list.deepmap: *.take
}

#===========================================================
# LLM configuration
#===========================================================

my @mustPassConfKeys = <name prompts examples temperature max-tokens stop-tokens api-key api-user-id>;

#| LLM configuration creation and retrieval.
our proto llm-configuration(|) is export {*}

multi sub llm-configuration($spec, *%args) {
    my $resObj =
            do given $spec {
                when Whatever {
                    llm-configuration('openai')
                }

                when $_ ~~ Str && $_.lc eq 'openai' {

                    LLM::Functions::Configuration.new(
                            name => 'openai',
                            api-key => Whatever,
                            api-user-id => 'user:' ~ ((10 ** 11 + 1) .. 10 ** 12).pick,
                            module => 'WWW::OpenAI',
                            model => 'text-davinci-003',
                            function => &OpenAITextCompletion,
                            temperature => 0.8,
                            max-tokens => 300,
                            total-probability-cutoff => 0.03,
                            prompts => Empty,
                            prompt-delimiter => ' ',
                            examples => Empty,
                            stop-tokens => Empty,
                            argument-renames => %('api-key' => 'auth-key', 'stop-tokens' => 'stop'),
                            format => 'values');
                }

                when $_ ~~ Str && $_.lc eq 'chatgpt' {

                    my $obj = llm-configuration('openai',
                            name => 'chatgpt',
                            function => &OpenAIChatCompletion,
                            model => 'gpt-3.5-turbo',
                            |%args.grep({ $_.key ∈ @mustPassConfKeys }).Hash);

                    $obj.evaluator = LLM::Functions::EvaluatorChat.new(conf => $obj);

                    $obj;
                }

                when $_ ~~ Str && $_.lc eq 'palm' {

                    LLM::Functions::Configuration.new(
                            name => 'palm',
                            api-key => Whatever,
                            api-user-id => 'user:' ~ ((10 ** 11 + 1) .. 10 ** 12).pick,
                            module => 'WWW::PaLM',
                            model => 'text-bison-001',
                            function => &PaLMGenerateText,
                            temperature => 0.4,
                            max-tokens => 300,
                            total-probability-cutoff => 0,
                            prompts => Empty,
                            prompt-delimiter => ' ',
                            examples => Empty,
                            stop-tokens => Empty,
                            argument-renames => %('api-key' => 'auth-key',
                                                  'max-tokens' => 'max-output-tokens',
                                                  'stop-tokens' => 'stop-sequences'),
                            format => 'values');
                }

                when $_ ~~ Str && $_.lc ∈ <chatpalm chat-palm palmchat palm-chat> {
                    llm-configuration(
                            'palm',
                            name => 'chatpalm',
                            function => &PaLMGenerateMessage,
                            model => 'chat-bison-001',
                            |%args.grep({ $_.key ∈ @mustPassConfKeys }).Hash)
                }

                default {
                    llm-configuration('openai')
                }
            }

    if %args {
        return llm-configuration($resObj, |%args);
    }
    return $resObj;
}

multi sub llm-configuration(LLM::Functions::Evaluator $evlr, *%args) {
    return llm-configuration($evlr.conf, |%args);
}

multi sub llm-configuration(LLM::Functions::Configuration $conf, *%args) {

    # Make the corresponding configuration hash and modify it
    my %newConf = $conf.Hash;
    my @knownKeys = %newConf.keys;

    # Nice and concise but does not work because Raku containerizes the array(s)
    %newConf = merge-hash(%newConf, %args);
    %newConf = %newConf.grep({ $_.key ∈ @knownKeys });

    # Create object
    my $newConf = LLM::Functions::Configuration.new(|%newConf);

    # I do not why I should be doing the following assignments.
    # At this point if, say, 'prompts' is in %args then
    # $newConf has it containerized in an array, e.g. [$(...),]
    # Maybe these explanations for Perl apply : https://www.perlmonks.org/?node_id=347308
    # BTW, just using .flat does not work: .&reallyflat must be used.

    if %args<prompts>:exists {
        $newConf.prompts = %args<prompts>.&reallyflat;
    } else {
        $newConf.prompts = $newConf.prompts.&reallyflat;
    }

    if %args<examples>:exists {
        $newConf.examples = %args<examples>.&reallyflat;
    } else {
        $newConf.examples = $newConf.examples.&reallyflat;
    }

    if %args<tools>:exists {
        $newConf.tools = %args<tools>.&reallyflat;
    } else {
        $newConf.tools = $newConf.tools.&reallyflat;
    }

    if %args<stop-tokens>:exists {
        $newConf.stop-tokens = %args<stop-tokens>.&reallyflat;
    } else {
        $newConf.stop-tokens = |$newConf.stop-tokens.&reallyflat;
    }

    # Result
    return $newConf;
}


#===========================================================
# Get LLM evaluator
#===========================================================
#| LLM evaluator creation.
proto sub llm-evaluator(|) is export {*}

multi sub llm-evaluator(*%args) {
    return llm-evaluator(Whatever, |%args);
}

multi sub llm-evaluator($llm-evaluator is copy, *%args) {

    # Default evaluator class
    my $evaluatorClass = %args<llm-evaluator-class>:exists ?? %args<llm-evaluator-class> !! Whatever;
    if $evaluatorClass.isa(Whatever) { $evaluatorClass = LLM::Functions::Evaluator; }

    die 'The value of llm-evaluator-class is expected to be Whatever or of type LLM::Functions::Evaluator.'
    unless $evaluatorClass ~~ LLM::Functions::Evaluator;

    # Separate configuration from evaluator options
    my @attrConf = LLM::Functions::Configuration.^attribute_table.values>>.name.map({ $_.substr(2) });

    my %argsConf = %args.grep({ $_.key ∈ @attrConf });
    my %argsEvlr = %args.grep({ $_.key ∉ %argsConf.keys && $_.key ne 'llm-evaluator-class' });

    # Create evaluator object
    $llm-evaluator = do given $llm-evaluator {

        when Whatever {
            $evaluatorClass.new(conf => llm-configuration('openai', |%argsConf), |%argsEvlr);
        }

        when WhateverCode {
            $evaluatorClass.new(conf => llm-configuration('openai', |%argsConf), |%argsEvlr);
        }

        when $_ ~~ Str:D {
            llm-evaluator(llm-configuration($_, |%argsConf), |%argsEvlr, llm-evaluator-class => %args<llm-evaluator-class> // Whatever);
        }

        when $_ ~~ LLM::Functions::Configuration {

            my $conf = $_.clone;

            if $conf.evaluator.isa(Whatever) {
                $evaluatorClass.new(:$conf, |%argsEvlr);

            } else {
                die 'The configuration attribute .evaluator is expected to be of type if LLM::Functions::Evaluator or Whatever.'
                unless $conf.evaluator ~~ LLM::Functions::Evaluator;

                $conf.evaluator.conf = $conf;

                $conf.evaluator
            }
        }

        when $_ ~~ LLM::Functions::Evaluator {
            my $res = $_.clone;
            my $conf = $_.conf.clone;

            with %argsEvlr<conf> {
                $conf = llm-configuration($conf, |%argsEvlr<conf>.Hash);
            }

            if %argsConf {
                $conf = llm-configuration($conf, |%argsConf);
            }
            $res.conf = $conf;

            with %argsEvlr<formatron> {
                $res.formatron = %argsEvlr<formatron>;
            }
            # Should we assign to the evaluator field here?
            # $res.conf.evaluator is Whatever by default.
            #$res.conf.evaluator = $res;

            $res
        }
    }

    die 'The first argument is expected to be Whatever, or one of the types Str:D, LLM::Functions::Evaluator, or LLM::Functions::Configuration.'
    unless $llm-evaluator ~~ LLM::Functions::Evaluator;

    return $llm-evaluator;
}


#===========================================================
# LLM Function
#===========================================================

#-----------------------------------------------------------
#| Represents a template for a large language model(LLM) prompt.
#| C<$prompt> -- A string or a function (optional.)
#| C<:form(:$formatron)> -- Specification how the output to processed.
#| C<:e(:$llm-evaluator)> -- Evaluator object specification.
our proto llm-function(|) is export {*}

# No positional args
multi sub llm-function(:form(:$formatron) = 'Str',
                       :e(:$llm-evaluator) is copy = Whatever) {
    return llm-function('', :$llm-evaluator);
}

# Using a string
multi sub llm-function(Str $prompt,
                       :form(:$formatron) = 'Str',
                       :e(:$llm-evaluator) is copy = Whatever) {

    $llm-evaluator = llm-evaluator($llm-evaluator);

    $llm-evaluator.conf.prompts.append($prompt);
    $llm-evaluator.formatron = $formatron;

    return -> $text, *%args { $llm-evaluator.eval($text, |%args) };
}

# Using a function
multi sub llm-function(&queryFunc,
                       :form(:$formatron) = 'Str',
                       :e(:$llm-evaluator) is copy = Whatever) {

    $llm-evaluator = llm-evaluator($llm-evaluator);
    $llm-evaluator.formatron = $formatron;

    # Find known parameters
    my @queryFuncParamNames = &queryFunc.signature.params.map({ $_.usage-name });

    $llm-evaluator.conf.prompts.append('');

    return -> **@args, *%args {
        # Get the named arguments for the query function
        my %args2 = %args.grep({ $_.key ∉ <prompts> && $_.key ∈ @queryFuncParamNames }).Hash;

        # Evaluate the query function with concrete arguments
        my $text = &queryFunc(|@args, |%args2);

        # Get the named arguments for the LLM evaluator
        my %args3 = %args.grep({ $_.key ∉ <prompts> && $_.key ∉ @queryFuncParamNames }).Hash;

        # LMM-evaluate
        $llm-evaluator.eval($text, |%args3)
    };
}


#===========================================================
# LLM Example Function
#===========================================================

#-----------------------------------------------------------
#| Creates an LLMFunction from few-shot examples.
our proto llm-example-function(|) is export {*}

multi sub llm-example-function(Pair $pair, *%args) {
    if $pair.key ~~ Positional &&
            $pair.value ~~ Positional &&
            $pair.key.elems == $pair.value.elems {
        my @pairs = $pair.key Z=> $pair.value;
        return llm-example-function(@pairs, |%args);
    } else {
        return llm-example-function([$pair,], |%args);
    }
}

multi sub llm-example-function(%training, *%args) {
    return llm-example-function(%training.pairs, |%args);
}

multi sub llm-example-function(@pairs,
                               :$hint is copy = Whatever,
                               :form(:$formatron) = 'Str',
                               :e(:$llm-evaluator) is copy = Whatever) {

    if @pairs.all ~~ Pair {

        $llm-evaluator = llm-evaluator($llm-evaluator);

        if $llm-evaluator ~~ LLM::Functions::EvaluatorChatPaLM {

            given $hint {
                when $_ ~~ Str && $_.chars > 0 {
                    $llm-evaluator.context = $hint;
                }
                when Whatever {
                    $llm-evaluator.context = 'You are a predictor trained with input-output examples.';
                }
            }

            $llm-evaluator.examples = @pairs.map( -> $x { "{ $x.key.Str }" => "{ $x.value.Str }" }).Array;

            return llm-function({ "$_" }, :$formatron, :$llm-evaluator);

        } else {
            my $pre = @pairs.map({ "Input: { $_.key.Str } \n Output: { $_.value.Str } \n" }).join("\n");

            if $hint ~~ Str && $hint.chars > 0 {
                $hint = $hint ~~ /<punct> $/ ?? $hint !! $hint ~ '.';
                $pre = "$hint\n\n$pre";
            }

            return llm-function({ $pre ~ "\nInput: $_\nOutput:" }, :$formatron, :$llm-evaluator);
        }
    }

    die "The first argument is expected to be a list of pairs or a pair of two positionals with the same length.";
}

#===========================================================
# LLM Chat object
#===========================================================

#| Creates a new chat object.
#| Signatures: C<llm-chat($chat, *%args)>, C<llm-chat($prompt, *%args)>, C<llm-chat(:$prompt, *%args)>.
#| C<$chat> -- Chat object.
#| C<$prompt> -- A prompt string.
#| C<*%args> -- Named arguments to make the evaluator object.
proto sub llm-chat(|) is export {*}

multi sub llm-chat(LLM::Functions::Chat $chat, *%args) {
    return $chat.clone.re-assign(|%args);
}

multi sub llm-chat($prompt = '', *%args) {
    return llm-chat(:$prompt, |%args);
}

multi sub llm-chat(:$prompt = '', *%args) {

    # Get evaluator spec
    my $spec = %args<llm-evaluator> // %args<llm-configuration> // %args<conf> // Whatever;

    # Default evaluator class
    my $evaluatorClass = %args<llm-evaluator-class>:exists ?? %args<llm-evaluator-class> !! Whatever;

    die 'The value of llm-evaluator-class is to be Whatever or of the type LLM::Functions::EvaluatorChat.'
    unless $evaluatorClass.isa(Whatever) || $evaluatorClass ~~ LLM::Functions::EvaluatorChat;

    # Make evaluator object
    my $llmEvalObj = do given $spec {
        when $_.isa(Whatever) {

            # Make Configuration object
            my $conf = llm-configuration('ChatGPT', prompts => $prompt, |%args);

            # Make Evaluator object
            LLM::Functions::EvaluatorChat.new(:$conf, formatron => %args<form> // %args<formatron>);
        }

        when $_.isa(LLM::Functions::Configuration) || $_.isa(LLM::Functions::Evaluator) || $_ ~~ Str:D {

            # Make Configuration object
            my $conf = llm-configuration($_, prompts => $prompt, |%args);

            # Obtain Evaluator class
            if $evaluatorClass.isa(Whatever) {
                if $conf.name ~~ /:i palm / {
                    $conf = llm-configuration('ChatPaLM',
                                    |$conf.Hash.grep({ $_.key ∈ @mustPassConfKeys }).Hash);

                    $evaluatorClass = LLM::Functions::EvaluatorChatPaLM
                } else {
                    $evaluatorClass = LLM::Functions::EvaluatorChat;
                }
            }

            # Make Evaluator object
            $evaluatorClass.new(:$conf, formatron => %args<form> // %args<formatron>);
        }

        default {
            die "Cannot obtain or make a LLM evaluator object with the given specs.";
        }
    }

    # Result
    my %args2 = %args.grep({ $_.key ∉ <llm-evaluator llm-configuration conf prompt form formatron> });
    return LLM::Functions::Chat.new(llm-evaluator => $llmEvalObj, |%args2);
}