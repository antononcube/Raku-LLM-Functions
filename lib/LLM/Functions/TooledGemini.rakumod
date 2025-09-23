use v6.d;

use LLM::Tooling;
use LLM::Functions::Tooled;
use WWW::Gemini;
use JSON::Fast;

class LLM::Functions::TooledGemini is LLM::Functions::Tooled {

    sub normalize-tool-spec(%spec is copy) {
        if %spec<function>:exists { %spec = %spec<function> }

        # Just calling :delete should be fine, but I want be explicit
        if %spec<type>:exists { %spec<type>:delete }
        if %spec<strict>:exists { %spec<strict>:delete }

        # Clean
        if %spec<parameters>:exists {
            %spec<parameters><additionalProperties>:delete;
            %spec<parameters><type>:delete;
            %spec<parameters><type> = 'object';
        }

        return %spec;
    }

    # Helper: extract ToolRequests from a Gemini candidate content
    sub extract-tool-requests(%assistant-content) {
        my @requestObjects;
        if %assistant-content<parts> {
            for |%assistant-content<parts> -> %part {
                if %part<functionCall> && %part<functionCall><name> {
                    my $name = %part<functionCall><name>;
                    my %args = (%part<functionCall><args> // {}).Hash;
                    @requestObjects.push: LLM::ToolRequest.new($name, %args);
                }
            }
        }
        return @requestObjects;
    }

    #| Synthesize with tools in a loop until the LLM returns a final, non-tool response.
    #| Arg 1 ($prompt): Str with the user messages.
    #| Arg 2 (@tool-objects): Array of LLM::Tool objects (callable tool implementations).
    multi method eval(@texts, *%args) {

        # To echo or not
        my $echo = %args<echo> // False;

        # Clone configuration
        my $confLocal = self.conf.clone;

        note "Configuration : { $confLocal.raku }" if $echo;

        # Get parameters
        my $model = $confLocal.model // "gemini-2.0-flash";

        my @tool-objects = |%args<tool-objects>;
        die 'The value of :@tool-objects is expected to be a list of LLM::Tool objects.'
        unless @tool-objects.all ~~ LLM::Tool:D;

        my @tool-specs = %args<tool-specs> // Empty;
        my %tool-config = %args<tool-config> // $confLocal.tool-config // { functionCallingConfig => { mode => "ANY" } };
        my $max-iterations = %args<max-iterations> // 8;

        # Make "full" prompt
        my $prompt = $confLocal.prompts.join($confLocal.prompt-delimiter).trim;

        # This likely should use the method
        # LLM::Functions::EvaluatorChatGemini.prompt-texts-combiner,
        # not the generic one
        $prompt = self.prompt-texts-combiner($prompt, @texts);

        # 1) Normalize initial user messages -> Gemini "messages"
        my @messages = [%( role => 'user', parts => [ %( text => $prompt ), ] ), ];

        # 2) Get tool specs for Gemini (either provided or derived from tool objects)

        if !@tool-specs.elems {
            @tool-specs = @tool-objects.map({ llm-tool-definition($_.info, format => 'hash', :!warn) });
        }

        @tool-specs .= map({ normalize-tool-spec($_) });

        # Normalize and exclude parameters
        my %args2 = $confLocal.normalize-params(%args, <prompt prompts tools format echo tool-config tool-objects>);

        # Proclaim
        note "Normalized additional parameters => {%args2.raku}" if $echo;

        # First call
        my $response = gemini-generate-content(
                @messages,
                tools => @tool-specs,
                :%tool-config,
                format => 'hash',
                |%args2);

        # Safety loop
        my $iterations = 0;

        loop {
            $iterations++;
            note "LLM invocation : $iterations" if $echo;

            if $iterations > $max-iterations {
                note "LLM execution with tools exceeded max loops, ($max-iterations). Returning the last response.";
                return $response;
            }

            note (:$response) if $echo;

            # Extract first candidate’s content
            my %assistant-message = $response<candidates>[0]<content>;

            # 4) If the LLM returned tool-call(s), run them locally and continue
            my @requests = extract-tool-requests(%assistant-message);

            if @requests.elems {
                # 4.1–4.3 Compute with the tools and add functionResponse messages
                my @funcParts = @requests.map({ generate-llm-tool-response(@tool-objects, $_) })».Hash('Gemini');

                if $echo {
                    note 'Tool responses:';
                    .note for @funcParts;
                }

                # Make and add the user response
                my %function-response =
                        role => 'user',
                        parts => @funcParts;

                @messages.push(%function-response);

                # 4.4 Extend conversation:
                #  - include the assistant message that requested tools
                #  - include our functionResponse messages with results
                @messages.push(%assistant-message);
                @messages.push(%function-response);

                # 4.5 goto loop (send back to the LLM)
                # Send the second request with function result
                $response = gemini-generate-content(
                        @messages,
                        tools => @tool-specs,
                        format => 'hash',
                        |%args2);

                next;
            }

            # 5) No tool calls — return the last LLM result (entire candidate content)
            my @processed = $response<candidates>.map({ $_<content><parts>.map({ $_<text> }) });
            return @processed.elems == 1 ?? @processed.head !! @processed;
        }
    }
}