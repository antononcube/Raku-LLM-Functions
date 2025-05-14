use JSON::Fast;
use Hash::Merge;

use WWW::OpenAI;
use WWW::OpenAI::TextCompletions;
use WWW::OpenAI::ChatCompletions;
use WWW::OpenAI::Embeddings;

use WWW::PaLM;
use WWW::PaLM::GenerateText;
use WWW::PaLM::GenerateMessage;
use WWW::PaLM::EmbedText;

use WWW::Gemini;
use WWW::Gemini::GenerateContent;
use WWW::Gemini::EmbedContent;

use WWW::MistralAI;
use WWW::MistralAI::ChatCompletions;
use WWW::MistralAI::Embeddings;

use WWW::LLaMA;
use WWW::LLaMA::TextCompletions;
use WWW::LLaMA::ChatCompletions;
use WWW::LLaMA::Embeddings;

use LLM::Functions::Chat;
use LLM::Functions::Configuration;
use LLM::Functions::Evaluator;
use LLM::Functions::EvaluatorChat;
use LLM::Functions::EvaluatorChatGemini;
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

my @mustPassConfKeys = <name prompts examples temperature max-tokens stop-tokens api-key api-user-id base-url tools>;
my @mustPassConfKeysExt = @mustPassConfKeys.push('model');

#| LLM configuration creation and retrieval.
our proto llm-configuration(|) is export {*}

multi sub llm-configuration($spec, *%args) {
    my $resObj =
            do given $spec {
                when Whatever {
                    llm-configuration('chatgpt')
                }

                when $_ ~~ Str:D && $_.lc eq 'openai' {

                    LLM::Functions::Configuration.new(
                            name => 'openai',
                            api-key => Whatever,
                            api-user-id => 'user:' ~ ((10 ** 11 + 1) .. 10 ** 12).pick,
                            module => 'WWW::OpenAI',
                            base-url => openai-base-url(),
                            model => 'gpt-3.5-turbo-instruct',
                            function => &OpenAITextCompletion,
                            embedding-model => 'text-embedding-3-small',
                            embedding-function => &OpenAIEmbeddings,
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

                when $_ ~~ Str:D && $_.lc eq 'chatgpt' {

                    my $obj = llm-configuration('openai',
                            name => 'chatgpt',
                            function => &OpenAIChatCompletion,
                            model => 'gpt-3.5-turbo',
                            |%args.grep({ $_.key ∈ @mustPassConfKeys }).Hash);

                    $obj.evaluator = LLM::Functions::EvaluatorChat.new(conf => $obj);

                    $obj;
                }

                when $_ ~~ Str:D && $_.lc ∈ <llama llamafile> {

                    my $obj = llm-configuration('chatpgt',
                            name => 'llama',
                            model => 'llama',
                            function => &LLaMAChatCompletion,
                            base-url => 'http://127.0.0.1:8080',
                            embedding-model => 'llama-embedding',
                            embedding-function => &LLaMAEmbeddings,
                            module => 'WWW::LLaMA',
                            |%args.grep({ $_.key ∈ @mustPassConfKeys }).Hash);

                    $obj.evaluator = LLM::Functions::EvaluatorChat.new(conf => $obj);

                    $obj;
                }

                when $_ ~~ Str:D && $_.lc eq 'palm' {

                    LLM::Functions::Configuration.new(
                            name => 'palm',
                            api-key => Whatever,
                            api-user-id => 'user:' ~ ((10 ** 11 + 1) .. 10 ** 12).pick,
                            module => 'WWW::PaLM',
                            base-url => '',
                            model => 'text-bison-001',
                            function => &PaLMGenerateText,
                            embedding-model => 'embedding-gecko-001',
                            embedding-function => &PaLMEmbedText,
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

                when $_ ~~ Str:D && $_.lc ∈ <chatpalm chat-palm palmchat palm-chat> {
                    llm-configuration(
                            'palm',
                            name => 'chatpalm',
                            function => &PaLMGenerateMessage,
                            model => 'chat-bison-001',
                            |%args.grep({ $_.key ∈ @mustPassConfKeys }).Hash)
                }

                when $_ ~~ Str:D && $_.lc ∈ <gemini chatgemini> {

                    LLM::Functions::Configuration.new(
                            name => 'gemini',
                            api-key => Whatever,
                            api-user-id => 'user:' ~ ((10 ** 11 + 1) .. 10 ** 12).pick,
                            module => 'WWW::Gemini',
                            base-url => '',
                            model => 'gemini-2.0-flash-lite',
                            function => &GeminiGenerateContent,
                            embedding-model => 'embedding-001',
                            embedding-function => &GeminiEmbedContent,
                            temperature => 0.4,
                            max-tokens => 300,
                            total-probability-cutoff => 0,
                            prompts => Empty,
                            prompt-delimiter => ' ',
                            examples => Empty,
                            stop-tokens => Empty,
                            base-url => 'https://generativelanguage.googleapis.com/v1beta/models',
                            argument-renames => %('api-key' => 'auth-key',
                                                  'max-tokens' => 'max-output-tokens',
                                                  'stop-tokens' => 'stop-sequences'),
                            format => 'values');
                }

                when $_ ~~ Str:D && $_.lc ∈ <mistralai mistral mistral-chat chatmistral> {

                    LLM::Functions::Configuration.new(
                            name => 'mistralai',
                            api-key => Whatever,
                            api-user-id => 'user:' ~ ((10 ** 11 + 1) .. 10 ** 12).pick,
                            module => 'WWW::MistralAI',
                            base-url => mistralai-base-url(),
                            model => 'mistral-tiny',
                            function => &MistralAIChatCompletion,
                            embedding-model => 'mistral-embed',
                            embedding-function => &MistralAIEmbeddings,
                            temperature => 0.6,
                            max-tokens => 300,
                            total-probability-cutoff => 0.03,
                            prompts => Empty,
                            prompt-delimiter => ' ',
                            examples => Empty,
                            stop-tokens => Empty,
                            argument-renames => %('api-key' => 'auth-key'),
                            format => 'values');
                }

                default {
                    llm-configuration('chatgpt')
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

    if %args<images>:exists {
        $newConf.images = %args<images>.&reallyflat;
    } else {
        $newConf.images = $newConf.images.&reallyflat;
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
            $evaluatorClass.new(conf => llm-configuration('chatgpt', |%argsConf), |%argsEvlr);
        }

        when WhateverCode {
            $evaluatorClass.new(conf => llm-configuration('chatgpt', |%argsConf), |%argsEvlr);
        }

        when $_ ~~ Str:D {
            llm-evaluator(llm-configuration($_, |%argsConf), |%argsEvlr,
                    llm-evaluator-class => %args<llm-evaluator-class> // Whatever);
        }

        when $_ ~~ LLM::Functions::Configuration {

            my $conf = $_.clone;
            with %argsEvlr<conf> {
                $conf = llm-configuration($conf, |%argsEvlr<conf>.Hash);
            }

            if %argsConf {
                $conf = llm-configuration($conf, |%argsConf);
            }

            if $conf.evaluator.isa(Whatever) {
                $evaluatorClass.new(:$conf, |%argsEvlr);

            } else {
                die 'The configuration attribute .evaluator is expected to be of type LLM::Functions::Evaluator or Whatever.'
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
    return llm-function('', :$formatron, :$llm-evaluator);
}

# Using a string
multi sub llm-function(Str $prompt,
                       :form(:$formatron) = 'Str',
                       :e(:$llm-evaluator) is copy = Whatever) {
    return llm-function([$prompt,], :$formatron, :$llm-evaluator);
}

# Using an array of strings
multi sub llm-function(@prompts where @prompts.all ~~ Str:D,
                       :form(:$formatron) = 'Str',
                       :e(:$llm-evaluator) is copy = Whatever) {

    $llm-evaluator = llm-evaluator($llm-evaluator);

    $llm-evaluator.conf.prompts.append(@prompts.Slip);
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

    # Make the pure function
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
#| C<$training> -- Input-to-output example(s) given as a Pair, an array of Pairs, or a Map.
#| C<:form(:$formatron)> -- Specification how the output to processed.
#| C<:e(:$llm-evaluator)> -- Evaluator object specification.
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

            $llm-evaluator.examples = @pairs.map(-> $x { "{ $x.key.Str }" => "{ $x.value.Str }" }).Array;

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
# LLM Synthesise
#===========================================================

#-----------------------------------------------------------
#| Generates text using by a combination prompts.
#| C<$prompt> -- Prompt(s) to synthesize LLM generative response with.
#| C<$prop> -- Property or properties to return, one of <FullText CompletionText PromptText>.
#| C<:form(:$formatron)> -- Specification how the output to processed.
#| C<:e(:$llm-evaluator)> -- Evaluator object specification.
our proto sub llm-synthesize($prompt,
                             $prop = Whatever,
                             :form(:$formatron) = 'Str',
                             :e(:$llm-evaluator) is copy = Whatever) is export {*}

multi sub llm-synthesize($prompt,
                         $prop = Whatever,
                         :form(:$formatron) = 'Str',
                         :e(:$llm-evaluator) is copy = Whatever) {
    return llm-synthesize([$prompt,], $prop, :$formatron, :$llm-evaluator);
}

multi sub llm-synthesize(@prompts is copy,
                         $prop is copy = Whatever,
                         :form(:$formatron) = 'Str',
                         :e(:$llm-evaluator) is copy = Whatever) {

    # Process properties
    my @expectedProps = <FullText CompletionText PromptText>;
    if $prop.isa(Whatever) { $prop = 'CompletionText'; }
    die "The value of the second argument is expected to be Whatever or one of: { @expectedProps.join(', ') }."
    unless $prop ~~ Str:D && $prop ∈ @expectedProps;

    # Get evaluator
    my $evlr = llm-evaluator($llm-evaluator);

    # Add configuration prompts
    # If we do that then we should change evaluator spec
    @prompts = [|$evlr.conf.prompts, |@prompts];
    $evlr.conf.prompts = [];

    # Reduce prompts
    my @processed;
    for @prompts -> $p {
        given $p {
            when Str:D {
                @processed.push($p);
            }

            when Callable {

                my $pres;
                try {
                    $pres = $p.();
                }

                if $! || !$pres ~~ Str:D {
                    my @args = '' xx $p.arity;
                    $pres = $p(|@args);
                }

                @processed.push($pres);
            }
        }
    }

    # Find the separator from the configuration
    my $sep = $evlr.conf.prompt-delimiter;
    my $prompt = @processed.join($sep);

    # Post process
    return do given $prop {
        when 'FullText' {
            my $res = llm-function(:$formatron, :$llm-evaluator)($prompt);
            [|@processed, $res]
        }

        when 'PromptText' {
            $prompt
        }

        default {
            llm-function(:$formatron, :$llm-evaluator)($prompt)
        }
    }
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

    die 'The value of llm-evaluator-class is expected to be Whatever or of the type LLM::Functions::EvaluatorChat.'
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
                # PaLM and Gemini have special evaluator objects.
                if $conf.name ~~ /:i palm / {

                    $conf = llm-configuration('ChatPaLM', |$conf.Hash.grep({ $_.key ∈ @mustPassConfKeysExt }).Hash);

                    $evaluatorClass = LLM::Functions::EvaluatorChatPaLM

                } elsif $conf.name ~~ /:i gemini / {

                    $conf = llm-configuration('Gemini', |$conf.Hash.grep({ $_.key ∈ @mustPassConfKeysExt }).Hash);

                    $evaluatorClass = LLM::Functions::EvaluatorChatGemini

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

#===========================================================
# LLM vision synthesize
#===========================================================

# [2024-05-09] OpenAI's vision models are:
# 'gpt-4-vision-preview', 'gpt-4-1106-vision-preview', 'gpt-4-turbo-2024-04-09', 'gpt-4-turbo', 'gpt-4o'.
# It is stated by OpenAI that 'gpt-4o' is the cheapest.
# The most standard/mainstream seems to be 'gpt-4-turbo' and 'gpt-4o', which are both chat and vision models:
# https://platform.openai.com/docs/models/gpt-4-turbo-and-gpt-4
# https://platform.openai.com/docs/models/gpt-4o
sub get-vision-llm-evaluator($spec, @images, *%args) {
    return do given $spec {
        when $_.isa(Whatever) || ($_ ~~ Str:D) && $spec.lc eq 'chatgpt' {
            llm-evaluator("ChatGPT", model => %args<model> // 'gpt-4o', temperature => 0.2, |%args, :@images);
        }
        when ($_ ~~ Str:D) && $spec.lc ∈ <gemini chatgemini> {
            llm-evaluator("Gemini", model => %args<model> // 'gemini-pro-vision', temperature => 0.2, |%args, :@images);
        }
        default {
            llm-evaluator($spec, |%args, :@images);
        }
    }
}

#| Creates a new chat object.
#| Signatures: C<llm-vision-synthesize(@prompts, @images, *%args)>, C<llm-vision-synthesize($prompt, *%args)>.
#| C<$prompt> -- A prompt string or a list of prompt strings.
#| C<@images> -- List of images.
#| C<:form(:$formatron)> -- Specification how the output to processed.
#| C<:e(:$llm-evaluator)> -- LLM evaluator specification.
#| C<*%args> -- Named arguments to make the evaluator object.
proto sub llm-vision-synthesize(|) is export {*}

multi sub llm-vision-synthesize(:@images,
                                :form(:$formatron) = 'Str',
                                :e(:$llm-evaluator) is copy = Whatever,
                                *%args) {
    my $prompt = do if @images > 1 {
        'Give descriptions of the images:'
    } else {
        'Give description of the image:'
    }
    return llm-vision-synthesize([$prompt,], @images, :$formatron, :$llm-evaluator, |%args);
}

multi sub llm-vision-synthesize($prompt,
                                $image where $image ~~ Str,
                                :form(:$formatron) = 'Str',
                                :e(:$llm-evaluator) is copy = Whatever,
                                *%args) {
    return llm-vision-synthesize($prompt, [$image,], :$formatron, :$llm-evaluator, |%args);
}

multi sub llm-vision-synthesize(Str $prompt,
                                @images,
                                :form(:$formatron) = 'Str',
                                :e(:$llm-evaluator) is copy = Whatever,
                                *%args) {
    return llm-vision-synthesize([$prompt,], @images, :$formatron, :$llm-evaluator, |%args);
}

multi sub llm-vision-synthesize(@prompts,
                                @images,
                                :form(:$formatron) = 'Str',
                                :e(:$llm-evaluator) is copy = Whatever,
                                *%args) {
    $llm-evaluator = get-vision-llm-evaluator($llm-evaluator, @images, |%args);
    note "llm-evaluator => {$llm-evaluator.raku}" if %args<echo> // False;
    return llm-synthesize(@prompts, :$formatron, :$llm-evaluator);
}

#===========================================================
# LLM vision function
#===========================================================

#| Represents a template for a large language model(LLM) prompt over images.
#| C<$prompt> -- A string or a function (optional.)
#| C<@images> -- A list of image URLs, file names, or Base64 strings.
#| C<:form(:$formatron)> -- Specification how the output to processed.
#| C<:e(:$llm-evaluator)> -- LLM evaluator specification.
#| C<*%args> -- additional argument of llm-configuration.
proto sub llm-vision-function($prompt,
                              $images,
                              :form(:$formatron) = 'Str',
                              :e(:$llm-evaluator) is copy = Whatever,
                              *%args) is export {*}

multi sub llm-vision-function($prompt,
                              Str $image,
                              :form(:$formatron) = 'Str',
                              :e(:$llm-evaluator) is copy = Whatever,
                              *%args) {
    return llm-vision-function($prompt, [$image, ], :$formatron, :$llm-evaluator, |%args);
}

multi sub llm-vision-function($prompt,
                              @images,
                              :form(:$formatron) = 'Str',
                              :e(:$llm-evaluator) is copy = Whatever,
                              *%args) {
    $llm-evaluator = get-vision-llm-evaluator($llm-evaluator, @images, |%args);
    note "llm-evaluator => {$llm-evaluator.raku}" if %args<echo> // False;
    return llm-function($prompt, :$formatron, :$llm-evaluator);
}

#===========================================================
# LLM Embedding
#===========================================================

#| Generic function for a large language model(LLM) embeddings.
#| C<$content> -- A string or a list of strings
#| C<:e(:$llm-evaluator)> -- LLM evaluator specification.
#| C<*%args> -- additional argument of llm-configuration.
proto sub llm-embedding($content,
                        :e(:$llm-evaluator) is copy = Whatever,
                        *%args) is export {*}

multi sub llm-embedding($prompt,
                        :e(:$llm-evaluator) is copy = Whatever,
                        *%args) {
    return llm-embedding([$prompt], :$llm-evaluator, |%args);
}

multi sub llm-embedding(@prompts,
                        :e(:$llm-evaluator) is copy = Whatever,
                        *%args) {
    $llm-evaluator = llm-evaluator($llm-evaluator);
    return $llm-evaluator.embed(@prompts, |%args).Array;
}