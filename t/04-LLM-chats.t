use v6.d;

use lib '.';
use lib './lib';

use LLM::Functions;
use LLM::Functions::Configuration;
use LLM::Functions::Evaluator;

use Test;

plan *;

## 1
my $prompt1 = 'You are a gem expert and you give concise answers.';

ok llm-chat(chat-id => 'gem-expert-talk', conf => 'ChatPaLM', :$prompt1);

## 2
my $chat2 = llm-chat(chat-id => 'gem-expert-talk', llm-evaluator => 'ChatPaLM', :$prompt1);
is $chat2.llm-evaluator.conf.name.lc, 'chatpalm';

## 3
my $chat3 = $chat2.clone;
$chat3.messages.push($chat3.make-message(role => 'user', message => 'Another one.'));
is $chat3.messages.elems > $chat2.messages.elems, True;

## 4
my $prompt4 = 'This assistant is a gem expert and gives concise answers.';
my $llmEvalObj4 = LLM::Functions::ChatEvaluator.new(conf => llm-configuration('PaLM-Chat', prompts => $prompt4));

my $chat4a = LLM::Functions::Chat.new(llm-evaluator => $llmEvalObj4, chat-id => 'new-chat');
my $chat4b = llm-chat(prompt => $prompt4, conf => 'PaLM-Chat', chat-id => 'new-chat');

is-deeply
        $chat4a.llm-evaluator.conf.Hash.grep({ $_.key ∉ <api-user-id>}).Hash,
        $chat4b.llm-evaluator.conf.Hash.grep({ $_.key ∉ <api-user-id>}).Hash;

done-testing;
