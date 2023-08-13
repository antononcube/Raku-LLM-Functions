use v6.d;

use LLM::Functions::Evaluator;

class LLM::Functions::EvaluatorChat
        is LLM::Functions::Evaluator {

    submethod TWEAK {
        without self.conf { self.conf = Whatever; }
        without self.formatron { self.formatron = 'Str'; }
    }

    # Attributes with the same names exist in LLM::Functions::Chat.
    # Should they also be here?
    has Str $.user-role is rw = 'user';
    has Str $.assitant-role is rw = 'assistant';
    has Str $.system-role is rw = 'system';

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

        if $prompt {
            return [$!system-role => $prompt, |@messages];
        } else {
            return @messages;
        }
    }
}