use v6.d;

use LLM::Functions::Evaluator;

class LLM::Functions::EvaluatorChat
        is LLM::Functions::Evaluator {

    submethod TWEAK {
        without self.conf { self.conf = Whatever; }
        without self.formatron { self.formatron = 'Str'; }
    }

    has $.context is rw = Whatever;
    has $.examples is rw = Whatever;

    has Str $.user-role is rw = 'user';
    has Str $.assitant-role is rw = 'assistant';
    has Str $.system-role is rw = 'system';

    method process-examples(@messages, *%args) {
        my $examplesLocal = %args<examples> // self.examples;

        if !$examplesLocal.isa(Whatever) {
            die "When examples spec is provied it is expected to be a Positional of pairs."
            unless $examplesLocal ~~ Positional && $examplesLocal.all ~~ Pair;

            $examplesLocal .= map({ "Input: { $_.key.Str } \n Output: { $_.value.Str } \n" }).join("\n");

            @messages .= prepend($examplesLocal);
        }

        return @messages;
    }

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
}