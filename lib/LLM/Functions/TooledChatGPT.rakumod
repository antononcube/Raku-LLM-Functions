use v6.d;

use LLM::Tooling;
use LLM::Functions::Tooled;
use WWW::OpenAI;
use JSON::Fast;

class LLM::Functions::TooledChatGPT is LLM::Functions::Tooled {

    # Helper: extract ToolRequests from a Gemini candidate content
    sub extract-tool-requests(%assistant-content) {
        my @requestObjects;
        if %assistant-content<tool_calls> {
            for |%assistant-content<tool_calls> -> %part {
                if %part<function> && %part<function><name> {
                    my $name = %part<function><name>;
                    my %args = %part<function><arguments> ~~ Str:D ?? from-json(%part<function><arguments>) !! %part<function><arguments>;
                    @requestObjects.push( LLM::ToolRequest.new(:$name, :%args, id => %part<id> ) ) ;
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
        # ChatGPT does not have tool configuration argument
        # my %tool-config = %args<tool-config> // { functionCallingConfig => { mode => "ANY" } };
        my $max-iterations = %args<max-iterations> // 8,
        my $format = %args<format> // Whatever,

        # Make "full" prompt
        my $prompt = $confLocal.prompts.join($confLocal.prompt-delimiter).trim;

        # This likely should use the method
        # LLM::Functions::EvaluatorChatGemini.prompt-texts-combiner,
        # not the generic one
        $prompt = self.prompt-texts-combiner($prompt, @texts);

        # 1) Normalize initial user messages -> ChatGTPT "messages"
        my @messages = [%( role => 'user', content => $prompt ), ];

        # 2) Get tool specs for Gemini (either provided or derived from tool objects)

        if !@tool-specs.elems {
            @tool-specs = @tool-objects.map({ llm-tool-definition($_.info, format => 'hash') });
        }

        if !(@tool-specs.head<type>:exists) || !(@tool-specs.head<function>:exists) {
            @tool-specs .= map({ %(type => 'function', function => $_ ) })
        }

        # First call
        my $response = openai-chat-completion(
                @messages,
                :$model,
                tools => @tool-specs,
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
            my %assistant-message = $response[0]<message>;

            # 4) If the LLM returned tool-call(s), run them locally and continue
            my @requests = extract-tool-requests(%assistant-message);

            if @requests.elems {

                @messages.push({
                    role => "assistant",
                    tool_calls => %assistant-message<tool_calls>
                });

                # 4.1–4.3 Compute with the tools and add functionResponse messages
                my @funcParts = @requests.map({ generate-llm-tool-response(@tool-objects, $_) })».Hash('ChatGPT');

                if $echo {
                    note 'Tool responses:';
                    .note for @funcParts;
                }

                # Make and add the user response
                for @funcParts {
                    $_<content> .= Str;
                    @messages.push($_);
                }

                # 4.5 goto loop (send back to the LLM)
                # Send the second request with function result
                $response = openai-chat-completion(
                        @messages,
                        :$model,
                        tools => @tool-specs,
                        format => "hash");

                next;
            }

            # 5) No tool calls — return the last LLM result (entire candidate content)

            return %assistant-message<content>
        }
    }
}