use v6.d;

use JSON::Fast;
use Hash::Merge;

use WWW::OpenAI;
use WWW::OpenAI::Models;
use WWW::OpenAI::TextCompletions;
use WWW::OpenAI::ChatCompletions;

use WWW::PaLM;
use WWW::PaLM::Models;
use WWW::PaLM::GenerateText;
use WWW::PaLM::GenerateMessage;

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
                            argument-renames => %( 'api-key' => 'auth-key'),
                            format => 'values');
                }

                when $_ ~~ Str && $_.lc eq 'chatgpt' {

                    my $obj = llm-configuration('openai');

                    $obj.function = &OpenAIChatCompletion;
                    $obj.model = 'gpt-3.5-turbo';
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
                            argument-renames => %( 'api-key' => 'auth-key', 'max-tokens' => 'max-output-tokens'),
                            format => 'values');
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

sub get-llm-evaluator($llm-evaluator is copy) {

    $llm-evaluator = do given $llm-evaluator {

        when Whatever {
            LLM::Functions::Evaluator.new(conf => llm-configuration('openai'));
        }

        when WhateverCode {
            LLM::Functions::Evaluator.new(conf => llm-configuration('openai'));
        }

        when $_ ~~ Str {
            get-llm-evaluator(llm-configuration($_));
        }

        when $_ ~~ LLM::Functions::Configuration {

            my $conf = $_;

            if $conf.evaluator.isa(Whatever) {

                LLM::Functions::Evaluator.new(:$conf);

            } else {

                die 'The configuration attribute .evaluator is expected to be of type if LLM::Functions::Evaluator or Whatever.'
                unless $conf.evaluator ~~ LLM::Functions::Evaluator;

                $conf.evaluator.conf = $conf;

                $conf.evaluator
            }
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
multi sub llm-function(:$llm-evaluator is copy = Whatever) {
    return llm-function('', :$llm-evaluator);
}

# Using a string
multi sub llm-function(Str $prompt,
                       :$llm-evaluator is copy = Whatever) {

    $llm-evaluator = get-llm-evaluator($llm-evaluator);

    $llm-evaluator.conf.prompts.append($prompt);

    return -> $text, *%args { $llm-evaluator.eval($text, |%args) };
}

# Using a function
multi sub llm-function(&queryFunc,
                       :$llm-evaluator is copy = Whatever) {

    $llm-evaluator = get-llm-evaluator($llm-evaluator);

    # Find known parameters
    my @queryFuncParamNames = &queryFunc.signature.params.map({ $_.usage-name });

    $llm-evaluator.conf.prompts.append('');

    return -> **@args, *%args {
        my %args2 = %args.grep({ $_.key ∉ <prompts> && $_.key ∈ @queryFuncParamNames }).Hash;
        my $prompt = &queryFunc(|@args, |%args2);
        my $text = $llm-evaluator.conf.prompts[*-1] = $prompt;
        my %args3 = %args.grep({ $_.key ∉ <prompts> && $_.key ∉ @queryFuncParamNames }).Hash;
        $llm-evaluator.eval($text, |%args3)
    };
}
