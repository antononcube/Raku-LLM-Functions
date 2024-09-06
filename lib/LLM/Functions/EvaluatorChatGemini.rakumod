use LLM::Functions::EvaluatorChat;

# Should this class inherit from Evaluator or from EvaluatorChat
class LLM::Functions::EvaluatorChatGemini
        is LLM::Functions::EvaluatorChat {

    submethod TWEAK {
        self.assistant-role = 'model';
        self.system-role = 'user';
    }

    method prompt-texts-combiner($prompt, @texts, *%args) {
        my @messages = self.LLM::Functions::EvaluatorChat::prompt-texts-combiner($prompt, @texts, |%args);

        if @messages.elems ≥ 2 && @messages[0].key eq @messages[1].key eq self.system-role {
            @messages = [@messages.head, Pair.new(self.assistant-role, "OK."), @messages.tail(*-1)];
        }

        return @messages;
    }
}