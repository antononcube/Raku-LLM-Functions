use LLM::Functions::Evaluator;
use LLM::Functions::Configuration;
use LLM::Functions::TooledChatGPT;
use LLM::Functions::TooledGemini;
use LLM::Tooling;

class LLM::Functions::EvaluatorChat
        is LLM::Functions::Evaluator {

    has $.context is rw = Whatever;
    has $.examples is rw = Whatever;

    has Str $.user-role is rw = 'user';
    has Str $.assistant-role is rw = 'assistant';
    has Str $.system-role is rw = 'system';

    #------------------------------------------------------
    submethod TWEAK {
        without self.conf { self.conf = Whatever; }
        without self.formatron { self.formatron = 'Str'; }

        if self.conf ~~ LLM::Functions::Configuration && self.conf.prompts.all ~~ Str {
            my $contextLocal = self.conf.prompts.join(self.conf.prompt-delimiter);
            self.context = $contextLocal;
            self.conf.prompts = Empty;
        }
    }

    #------------------------------------------------------
    method combine-role-messages(@messages where @messages.all ~~ Pair) {
        my @resMessages = [@messages.head, ];
        for @messages.tail(*-1) -> $p {
            if $p.key eq @resMessages.tail.key {
                my $l = @resMessages.pop;
                @resMessages.push( Pair.new($p.key, [$l.value, $p.value].join(self.conf.prompt-delimiter)) );
            } else {
                @resMessages.push($p)
            }
        }
        return @resMessages;
    }

    #------------------------------------------------------
    method process-examples(@messages, *%args) {
        my $examplesLocal = %args<examples> // self.examples;

        if !$examplesLocal.isa(Whatever) {
            die "When examples spec is provided it is expected to be an Iterable of pairs."
            unless $examplesLocal ~~ Iterable && $examplesLocal.all ~~ Pair;

            $examplesLocal .= map({ "Input: { $_.key.Str } \n Output: { $_.value.Str } \n" }).join("\n");

            @messages .= prepend($examplesLocal);
        }

        return @messages;
    }

    #------------------------------------------------------
    method prompt-texts-combiner($prompt, @texts, *%args) {

        my @messages = do given @texts {
            when $_.all ~~ Str {
                (self.user-role X=> @texts);
            }
            when $_.all ~~ Pair {
                @texts;
            }

            when $_.all ~~ Map {
                @texts.map({ $_<role> => $_<content> }).Array;
            }

            default {
                die 'Unknown form of the second argument (@texts).';
            }
        };

        @messages = @messages.grep({ $_.key ne 'examples' });

        # Add prompt
        if $prompt {
            @messages .= prepend((self.user-role => $prompt));
        }

        # Combine role messages
        @messages = self.combine-role-messages(@messages);

        # Process context
        my $contextLocal = @messages.Hash<context> // %args<context> // self.context;

        if !$contextLocal.isa(Whatever) {
            die "When context spec is provied it is expected to be string."
            unless $contextLocal ~~ Str;

            @messages .= prepend((self.system-role => $contextLocal));
        }

        # Process examples
        @messages = self.process-examples(@messages, |%args);

        # Result
        return @messages;
    }

    #------------------------------------------------------
    #| Evaluate a structured chat transcript, invoking the configured tools.
    method eval-with-tools(@messages where @messages.all ~~ Map:D, *%args --> Hash) {

        my @tool-objects = %args<tool-objects>:exists
                ?? |%args<tool-objects>
                !! |self.conf.tools;

        die 'The configured tools are expected to be LLM::Tool objects.'
        unless @tool-objects.all ~~ LLM::Tool:D;

        # The chat keeps its system prompt in the evaluator context. Supply it
        # to the provider without adding a duplicate, persistent chat message.
        my @request-messages = @messages.map(*.Hash).Array;
        my $context = %args<context> // self.context;
        if $context ~~ Str:D && $context.chars
                && !@request-messages.grep({ ($_<role> // '') eq self.system-role }).elems {
            @request-messages.unshift(%(role => self.system-role, content => $context));
        }

        my LLM::Functions::Tooled:D $tool-evaluator = do given self.conf.name.lc {
            when /gemini/ { LLM::Functions::TooledGemini.new(conf => self.conf) }
            when /chatgpt|openai/ { LLM::Functions::TooledChatGPT.new(conf => self.conf) }
            default {
                die "No structured chat tool evaluator is available for configuration '{ self.conf.name }'.";
            }
        };

        my %result = $tool-evaluator.eval-chat(
                @request-messages,
                :@tool-objects,
                |%args);

        die 'A tool evaluator is expected to return a hash with result and messages.'
        unless (%result<result>:exists) && (%result<messages>:exists);

        %result<result> = self.post-process(%result<result>, form => %args<form> // Whatever);
        return %result;
    }

    #------------------------------------------------------
    #| To Hash
    method Hash (--> Hash) {
        return %(conf => self.conf.Hash, formatron => self.formatron,
                 :$!context, :$!examples, :$!assistant-role, :$!system-role, :$!user-role);
    }
}
