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

unit module LLM::Functions;

#===========================================================
# LLM configuration
#===========================================================

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
                            argument-renames => %('api-key' => 'auth-key'),
                            format => 'values');
                }

                when $_ ~~ Str && $_.lc eq 'chatgpt' {

                    my $obj = llm-configuration('openai',
                            name => 'chatgpt',
                            function => &OpenAIChatCompletion,
                            model => 'gpt-3.5-turbo');

                    $obj.evaluator = LLM::Functions::ChatEvaluator.new(conf => $obj);

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
                            argument-renames => %('api-key' => 'auth-key', 'max-tokens' => 'max-output-tokens'),
                            format => 'values');
                }

                when $_ ~~ Str && $_.lc ∈ <chatpalm chat-palm palmchat palm-chat> {
                    llm-configuration(
                            'palm',
                            name => 'chatpalm',
                            function => &PaLMGenerateMessage,
                            model => 'chat-bison-001')
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

multi sub llm-configuration(LLM::Functions::Configuration $conf, *%args) {

    # Make the corresponding configuration hash and modify it
    my %newConf = $conf.Hash;

    # Nice and concise but does not work because Raku containerizes the array(s)
    %newConf = merge-hash(%newConf, %args);

    # Create object
    my $newConf = LLM::Functions::Configuration.new(|%newConf);

    # I do not why I should be doing those assignments.
    # At this point if, say, 'prompts' is in %args then
    # $newConf has it containerized in an array, e.g. [$(...),]
    # Maybe these explanations for Perl apply : https://www.perlmonks.org/?node_id=347308

    if %args<prompts>:exists {
        $newConf.prompts = %args<prompts>;
    }

    if %args<tools>:exists {
        $newConf.tools = %args<tools>;
    }

    if %args<stop-tokens>:exists {
        $newConf.stop-tokens = %args<stop-tokens>;
    }

    # Result
    return $newConf;
}


#===========================================================
# Get LLM evaluator
#===========================================================

sub llm-evaluator($llm-evaluator is copy) {

    $llm-evaluator = do given $llm-evaluator {

        when Whatever {
            LLM::Functions::Evaluator.new(conf => llm-configuration('openai'));
        }

        when WhateverCode {
            LLM::Functions::Evaluator.new(conf => llm-configuration('openai'));
        }

        when $_ ~~ Str {
            llm-evaluator(llm-configuration($_));
        }

        when $_ ~~ LLM::Functions::Configuration {

            my $conf = $_.clone;

            if $conf.evaluator.isa(Whatever) {

                LLM::Functions::Evaluator.new(:$conf);

            } else {

                die 'The configuration attribute .evaluator is expected to be of type if LLM::Functions::Evaluator or Whatever.'
                unless $conf.evaluator ~~ LLM::Functions::Evaluator;

                $conf.evaluator.conf = $conf;

                $conf.evaluator
            }
        }

        when LLM::Functions::Evaluator {
            $_.clone;
        }
    }

    die 'The argument \$llm-evaluator is expected to be of type if LLM::Functions::Evaluator or Whatever.'
    unless $llm-evaluator ~~ LLM::Functions::Evaluator;

    return $llm-evaluator;
}


#===========================================================
# LLM Function
#===========================================================

#-----------------------------------------------------------
#| Represents a template for a large language model(LLM) prompt.
our proto llm-function(|) is export {*}

# No positional args
multi sub llm-function(:$form = 'Str',
                       :$llm-evaluator is copy = Whatever) {
    return llm-function('', :$llm-evaluator);
}

# Using a string
multi sub llm-function(Str $prompt,
                       :form(:$formatron) = 'Str',
                       :$llm-evaluator is copy = Whatever) {

    $llm-evaluator = llm-evaluator($llm-evaluator);

    $llm-evaluator.conf.prompts.append($prompt);
    $llm-evaluator.formatron = $formatron;

    return -> $text, *%args { $llm-evaluator.eval($text, |%args) };
}

# Using a function
multi sub llm-function(&queryFunc,
                       :form(:$formatron) = 'Str',
                       :$llm-evaluator is copy = Whatever) {

    $llm-evaluator = llm-evaluator($llm-evaluator);
    $llm-evaluator.formatron = $formatron;

    # Find known parameters
    my @queryFuncParamNames = &queryFunc.signature.params.map({ $_.usage-name });

    $llm-evaluator.conf.prompts.append('');

    return -> **@args, *%args {
        my %args2 = %args.grep({ $_.key ∉ <prompts> && $_.key ∈ @queryFuncParamNames }).Hash;
        my $prompt = &queryFunc(|@args, |%args2);
        my $text = $llm-evaluator.conf.prompts[*- 1] = $prompt;
        my %args3 = %args.grep({ $_.key ∉ <prompts> && $_.key ∉ @queryFuncParamNames }).Hash;
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
                               :$llm-evaluator is copy = Whatever) {

    if @pairs.all ~~ Pair {
        my $pre = @pairs.map({ "Input: { $_.key.Str } \n Output: { $_.value.Str } \n" }).join("\n");

        if $hint ~~ Str && $hint.chars > 0 {
            $hint = $hint ~~ /<punct> $/ ?? $hint !! $hint ~ '.';
            $pre = "$hint\n\n$pre";
        }

        return llm-function({ $pre ~ "\nInput: $_\nOutput:" }, :$formatron, :$llm-evaluator);
    }

    die "The first argument is expected to be a list of pairs or a pair of two positionals with the same length.";
}

#===========================================================
# LLM Chat object
#===========================================================

#| Creates a new chat object
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

    # Make evaluator object
    my $llmEvalObj = do given $spec {
        when $_.isa(Whatever) {
            LLM::Functions::ChatEvaluator.new(conf => llm-configuration('PaLM-Chat', prompts => $prompt));
        }

        when $_.isa(LLM::Functions::Configuration) {
            LLM::Functions::ChatEvaluator.new(conf => llm-configuration($_, prompts => $prompt));
        }

        when $_ ~~ Str:D {
            LLM::Functions::ChatEvaluator.new(conf => llm-configuration($_, prompts => $prompt));
        }

        when $_.isa(LLM::Functions::ChatEvaluator) {
            # Do nothing
        }

        default {
            die "Cannot obtain or make a LLM evaluator object with the given specs.";
        }
    }

    # Result
    my %args2 = %args.grep({ $_.key ∉ <llm-evaluator llm-configuration conf prompt>});
    return LLM::Functions::Chat.new(llm-evaluator => $llmEvalObj, |%args2);
}