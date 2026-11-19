use LLM::Functions;
use LLM::Resources;
use LLM::Prompts;

my $dir = $*HOME.add(<.codex skills>);
my @skill-dirs = dir($dir).grep(*.&is-valid-agent-skill);
.say for @skill-dirs».basename.sort;

my $model = 'gpt-5.6-luna';
#my $model = 'gpt-4.1';

my $conf = llm-configuration('chatgpt', skills => @skill-dirs, max-tokens => 8192, :$model, reasoning-effort => 'none');

my $chat = LLM::Functions::Chat.new(llm-evaluator => LLM::Functions::EvaluatorChat.new(:$conf), chat-id => 'raku-skilled-chat-object-' ~ now.DateTime.Str);

my $res = $chat.eval('With Raku, I want to chord plot for a primitive root of multiplicative integer group modulo, say, 250. Use "Math::NumberTheory"'):!echo;

say (:$res);