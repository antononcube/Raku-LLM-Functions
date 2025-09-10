use v6.d;

use LLM::Tooling;
use LLM::Functions::Tooled;
use WWW::Gemini;
use JSON::Fast;

class LLM::Functions::TooledGemini is LLM::Functions::Tooled {

    submethod TWEAK {
        self.service-style = 'Gemini'
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
    multi method synthesize(
            Str:D  $prompt,
            :@tool-objects where { .all ~~ LLM::Tool:D },
            :$model = "gemini-2.0-flash",
            :@tool-specs is copy = Empty,
            :%tool-config = { functionCallingConfig => { mode => "ANY" } },
            :$max-iterations = 8,
            :$format = Whatever,
            Bool:D :$echo = False) {

        # 1) Normalize initial user messages -> Gemini "messages"
        my @messages = [%( role => 'user', parts => [ %( text => $prompt ), ] ), ];

        # 2) Get tool specs for Gemini (either provided or derived from tool objects)

        if !@tool-specs.elems {
            @tool-specs = @tool-objects».json-spec
        }

        # First call
        my $response = gemini-generate-content(
                @messages,
                :$model,
                tools => @tool-specs,
                :%tool-config,
                format => 'hash');


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
                        :$model,
                        format => "hash");

                next;
            }

            # 5) No tool calls — return the last LLM result (entire candidate content)

            return do if $format ~~ Str:D && $format.lc ∈ <text values> {
                $response<candidates>[0]<content><parts>».<text>.join("\n");
            } else {
                $response<candidates>
            }
        }
    }
}