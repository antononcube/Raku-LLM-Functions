use v6.d;

use lib '.';
use lib './lib';

use LLM::Functions;

use Test;

plan *;

# With PaLM we have to make the assignment:
#     $chat.system-role = $chat.assistant-role;
# because:
#
# 1. By default LLM::Functions::Chat has three different roles: <user assistant system>.
#    So, we get the error:
#      error => {code => 400, message => Messages must have 0 or at most 2 authors: 3 specified., status => INVALID_ARGUMENT}
#
# 2. With:
#      $chat.system-role = $chat.user-role;
#     we get the error:
#      error => {code => 400, message => Messages must alternate between authors., status => INVALID_ARGUMENT}
#
# 3. Hence we make the following assignment and change the prompt to use "This assistant is ..." instead of "You are ..."


## 1
my $prompt1 = 'You are a gem expert and you give concise answers.';
my $chat1 = llm-chat(chat-id => 'gem-expert-talk', conf => 'ChatPaLM', :$prompt1);
$chat1.system-role = $chat1.assistant-role;

ok $chat1.eval('What is the most transparent gem?');

## 2
my $msg2 = 'Ok. What are the second and third most transparent gems?';
ok $chat1.eval($msg2);

## 3
my $msg3 = 'Which country buys gems the most?';
ok $chat1.eval($msg3);

## 4
my $msg4 = 'Which country exports gems the most?';
ok $chat1.eval($msg4);

## 5
is $chat1.messages.elems, 8;

## 6
is $chat1.messages.all ~~ Hash, True;

## 7
is-deeply
        $chat1.messages[2, 4, 6].map({ $_<content> }).Array,
        [$msg2, $msg3, $msg4];

done-testing;
