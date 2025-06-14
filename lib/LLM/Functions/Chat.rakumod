use LLM::Functions::EvaluatorChat;

class LLM::Functions::Chat {

    has Str $.chat-id is rw = '';
    has LLM::Functions::EvaluatorChat $.llm-evaluator is rw;
    has @.messages is rw;
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
    method prompt() {
        my $prompt = self.llm-evaluator.conf.prompts;
        if ! $prompt { $prompt = self.llm-evaluator.context; }
        if $prompt ~~ Positional {
           $prompt = $prompt.join(self.llm-evaluator.conf.prompt-delimiter)
        }
        return $prompt;
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

    multi method eval($message, $role = Whatever, *%args) {
        return self.eval(:$message, :$role, |%args);
    }

    multi method eval(:$message! is copy, :$role is copy = Whatever, *%args) {

        # Process role argument
        if $role.isa(Whatever) {
            $role = self.llm-evaluator.user-role;
        } else {
            self.llm-evaluator.user-role = $role
        }

        die 'The argument $role is expected to be a string or Whatever.'
        unless $role ~~ Str:D;

        if $message ~~ Str:D {
            $message = self.make-message(:$role, :$message);
        }

        die 'The argument $message is expected to be a string, a list of strings, or a hashmap.'
        unless $message ~~ Map:D;

        if $message<role>:!exists {
            $message<role> = $role
        }

        # Store message struct
        @!messages.push($message);

        # Get LLM result
        my $res;
        try {
            $res = $!llm-evaluator.eval(@!messages, |%args);
        }

        if $! {
            note 'Failure while evaluating the message. Message and response are not logged.';
            fail $!.payload;
        }

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
        my $assistant-role = self.llm-evaluator.assistant-role;
        @!messages.push(self.make-message(role => $assistant-role, message => $msgRes));

        # Result
        return $res;
    }

    #-------------------------------------------------------
    method Str(-->Str) {
        return self.gist;
    }

    #-------------------------------------------------------
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
    method form(:$delim is copy = Whatever) {
        if $delim.isa(Whatever) { $delim = ('⸺' x 60); }

        my $res = "Chat: { self.chat-id }";

        $res ~= "\n" ~ $delim;

        my $prompt = self.prompt;

        $res ~= "\n" ~ "Prompts: { $prompt.chomp }";

        if self.llm-evaluator.conf.examples {
            $res ~= "\n" ~ $delim;
            if self.llm-evaluator.conf.examples ~~ Positional {
                $res ~= "\n" ~ "Examples:";
                for self.llm-evaluator.conf.examples {
                    $res ~= "\n" ~ $_;
                }
            } else {
                $res ~= "\n" ~ "Examples: { self.llm-evaluator.conf.examples }";
            }
        }

        for self.messages -> %h {
            $res ~= "\n" ~ $delim;
            for <role content tool_calls tool_call_id timestamp> -> $prop {
                if %h{$prop}:exists {
                    $res ~= "\n" ~ $prop ~ ' : ' ~ %h{$prop}.gist;
                }
            }
        }

        return $res;
    }

    #-------------------------------------------------------
    method say(:$delim = Whatever) {
        say self.form(:$delim);
    }

    #-------------------------------------------------------
    method note(:$delim = Whatever) {
        note self.form(:$delim);
    }

}