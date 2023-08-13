use v6.d;

use LLM::Functions::Evaluator;

class LLM::Functions::EvaluatorChat
        is LLM::Functions::Evaluator {

    submethod TWEAK {
        without self.conf { self.conf = Whatever; }
        without self.formatron { self.formatron = 'Str'; }
    }

    has Str $.system-role is rw = 'system';

    method prompt-texts-combiner($prompt, @texts) {
        my @messages = do given @texts {
            when $_.all ~~ Str {
                ('user' X=> @texts);
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