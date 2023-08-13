use v6.d;

use LLM::Functions::EvaluatorChat;

class LLM::Functions::Chat {

    has Str $.chat-id is rw = '';
    has LLM::Functions::EvaluatorChat $.llm-evaluator is rw;
    has @.messages;
    has Str $.context is rw = '';
    has @.examples is rw = Empty;

    #-------------------------------------------------------
    method clone {
        nextwith :llm-evaluator($!llm-evaluator.clone), :messages(@!messages.clone), |%_
    }

    #-------------------------------------------------------
    method re-assign(*%args) {
        # There should be a more elegant way of doing this.
        with %args<chat-id>        { self.chat-id = %args<chat-id>; }
        with %args<llm-evaluator>  { self.llm-evaluator = %args<llm-evaluator>; }
        with %args<messages>       { self.messages = %args<messages>; }
        with %args<examples>       { self.messages = %args<examples>; }
        return self;
    }

    #-------------------------------------------------------
    multi method make-message(Str $message) {
        return self.make-message(role => Whatever, :$message, timestamp => DateTime.now);
    }

    multi method make-message(Str $role, Str $message) {
        return self.make-message(:$role, :$message, timestamp => DateTime.now);
    }

    multi method make-message(Str :$role!, Str :$message!, :$timestamp is copy = Whatever) {
        if $timestamp.isa(Whatever) { $timestamp = DateTime.now; }
        return %(:$role, content => $message, :$timestamp);
    }

    #-------------------------------------------------------
    multi method eval(@message, $role = Whatever, *%args) {
        return self.eval(message => @message.join(' '), :$role, |%args);
    }

    multi method eval(Str $message, $role = Whatever, *%args) {
        return self.eval(:$message, :$role, |%args);
    }

    multi method eval(Str :$message!, :$role is copy = Whatever, *%args) {

        # Process role argument
        if $role.isa(Whatever) {
            $role = self.llm-evaluator.user-role;
        } else {
            self.llm-evaluator.user-role = $role
        }

        die 'The argument $role is expected to be a string or Whatever.'
        unless $role ~~ Str:D;

        # Make and store message struct
        @!messages.push(self.make-message(:$role, :$message));

        # Get LLM result
        my $res = $!llm-evaluator.eval(@!messages, |%args);

        # Try to convert LLM response into a message
        my Str $msgRes;
        try {
            $msgRes = $res.Str;
        }

        if $! {
            note "Cannot store as a string the LLM response: ｢{ $res.raku }｣.";
            $msgRes = $res.raku;
        }

        # Make and store message response
        my $assistant-role = self.llm-evaluator.assitant-role;
        @!messages.push(self.make-message(role => $assistant-role, message => $msgRes));

        # Result
        return $res;
    }

    #-------------------------------------------------------
    method Str(-->Str) {
        return self.gist;
    }

    method gist(-->Str) {
        my $res = "LLM::Functions::Chat(chat-id = $!chat-id, llm-evaluator.conf.name = { self.llm-evaluator.conf.name }, messages.elems = { self.messages.elems }";

        if self.messages.elems {
            $res ~= ", last.message = { self.messages.tail.raku // 'Nil' })";
        } else {
            $res ~= ')'
        }

        return $res;
    }

    #-------------------------------------------------------
    method say(:$delim = ('⸺' x 60)) {
        say "Chat: { self.chat-id }";
        say $delim;
        say "Prompts: { self.llm-evaluator.conf.prompts }";
        if self.llm-evaluator.conf.examples {
            say $delim;
            if self.llm-evaluator.conf.examples ~~ Positional {
                say "Examples:";
                .say for self.llm-evaluator.conf.examples;
            } else {
                say "Examples: { self.llm-evaluator.conf.examples }";
            }
        }
        for self.messages -> %h {
            say $delim;
            .say for <role content timestamp>.map({ $_ => %h{$_} });
        }
    }
}