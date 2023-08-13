use v6.d;

use LLM::Functions::EvaluatorChat;

# Should this class inherit from Evaluator or from EvaluatorChat
class LLM::Functions::EvaluatorChatPaLM
        is LLM::Functions::EvaluatorChat {

    submethod TWEAK {
        self.system-role = 'context';
        self.conf.evaluator = self;
    }

    has $.examples is rw = Whatever;

    # In the terminology of PaLM the first argument, $prompt, is a "context".
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

        my $examples = @messages.Hash<examples> // %args<examples> // $!examples;

        if !$examples.isa(Whatever) {
            die "When examples spec is provied it is expected to be a Positional of pairs."
            unless $examples ~~ Positional && $examples.all ~~ Pair;

            @messages = @messages.push(:$examples);
        }

        if $prompt {
            return [self.system-role => $prompt, |@messages];
        } else {
            return @messages;
        }
    }
}