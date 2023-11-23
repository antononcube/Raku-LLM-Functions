use LLM::Functions::EvaluatorChat;

# Should this class inherit from Evaluator or from EvaluatorChat
class LLM::Functions::EvaluatorChatPaLM
        is LLM::Functions::EvaluatorChat {

    submethod TWEAK {
        self.system-role = 'context';
    }

    method process-examples(@messages, *%args) {
        my $examplesLocal = @messages.Hash<examples> // %args<examples> // self.examples;

        if !$examplesLocal.isa(Whatever) {
            die "When examples spec is provied it is expected to be a Iterable of pairs."
            unless $examplesLocal ~~ Iterable && $examplesLocal.all ~~ Pair;

            @messages .= grep({ $_.key ne 'examples' }).prepend((examples => $examplesLocal));
        }

        return @messages;
    }
}