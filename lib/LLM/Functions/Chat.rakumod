use v6.d;

use LLM::Functions::Evaluator;

class LLM::Functions::Chat {

    has Str $.chat-id is rw = '';
    has LLM::Functions::ChatEvaluator $.llm-evaluator is rw;
    has @.messages;
    has Str $.assistant-role is rw = 'assistant';
    has Str $.system-role is rw = 'system';

    method make-message(Str :$role!, Str :$message!) {
        return %(:$role,
                 content => $message,
                 timestamp => DateTime.now);
    }

    multi method eval(Str $message, Str $role = 'user', *%args) {
        return self.eval(:$message, :$role, |%args);
    }

    multi method eval(Str :$message!, Str :$role = 'user', *%args) {
        # Make and store message struct
        @!messages.push(self.make-message(:$role, :$message));

        $!llm-evaluator.system-role = $!system-role;

        # Get LLM result
        my $res = $!llm-evaluator.eval(@!messages, |%args);

        if $res !~~ Str {
            note $res;
            return Nil;
        }

        # Make and store message response
        @!messages.push(self.make-message(role => $!assistant-role, message => $res));

        # Result
        return $res;
    }
}