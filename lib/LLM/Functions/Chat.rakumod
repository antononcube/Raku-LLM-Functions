use v6.d;

use LLM::Functions::Evaluator;

class LLM::Functions::Chat {

    has Str $.chat-id is rw = '';
    has LLM::Functions::ChatEvaluator $.llm-evaluator is rw;
    has @.messages;
    has Str $.user-role is rw = 'user';
    has Str $.assistant-role is rw = 'assistant';
    has Str $.system-role is rw = 'system';

    #-------------------------------------------------------
    method clone { nextwith :llm-evaluator($!llm-evaluator.clone), :messages(@!messages.clone), |%_ }

    #-------------------------------------------------------
    method make-message(Str :$role!, Str :$message!) {
        return %(:$role,
                 content => $message,
                 timestamp => DateTime.now);
    }

    #-------------------------------------------------------
    multi method eval(Str $message, $role = Whatever, *%args) {
        return self.eval(:$message, :$role, |%args);
    }

    multi method eval(Str :$message!, :$role is copy = Whatever, *%args) {

        # Process role argument
        if $role.isa(Whatever) { $role = $!user-role; }

        die 'The argument $role is expected to be a string or Whatever.'
        unless $role ~~ Str:D;

        # Make and store message struct
        @!messages.push(self.make-message(:$role, :$message));

        # Make sure same system role is used in the evaluator object
        $!llm-evaluator.system-role = $!system-role;

        # Get LLM result
        my $res = $!llm-evaluator.eval(@!messages, |%args);

        # Do not proceed if failed
        if $res !~~ Str {
            note $res;
            return Nil;
        }

        # Make and store message response
        @!messages.push(self.make-message(role => $!assistant-role, message => $res));

        # Result
        return $res;
    }

    #-------------------------------------------------------
    method Str(-->Str) {
        return self.gist;
    }

    method gist(-->Str) {
        my $res = "LLM::Functions::Chat( chat-id = $!chat-id, llm-evaluator.conf.name = {self.llm-evaluator.conf.name}, messages.elems = {self.messages.elems}";

        if self.messages.elems {
            $res ~= ", last.message = {self.messages.tail.raku // 'Nil'})";
        } else {
            $res ~= ')'
        }

        return $res;
    }
}