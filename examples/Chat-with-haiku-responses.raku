#!/usr/bin/env raku
use v6.d;

use LLM::Functions;

# Following Google's PaLM example here:
# https://codelabs.developers.google.com/haiku-generator#4

# Make a Chat-PaLM evaluator object
my $llmEvalObj = LLM::Functions::EvaluatorChatPaLM.new(
        conf => llm-configuration(
                'ChatPaLM',
                prompts => "You are an awesome haiku writer.",
                examples => [
                    'Write a haiku about Google Photos.' => "Google Photos, my friend\nA journey of a lifetime\nCaptured in pixels"
                ],
                temperature => 0.5)
        );

# Show the object
#note (:$llmEvalObj);

# Make a new Chat object that uses the Chat-PaLM evaluator object
my $chat = LLM::Functions::Chat.new(llm-evaluator => $llmEvalObj, chat-id => 'new-PaLM-chat-' ~ now);

# Assign a product name
my $productName = 'kettlebell weights';

# Evaluate a message
say $chat.eval("Write a cool haiku for $productName."):!echo;

# Evaluate anotherR message
say '-' x 120;
say $chat.eval("Please redo it for a general, training device."):!echo;

# Show the whole chat
say '=' x 120;
say $chat.say;