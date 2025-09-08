use v6.d;

class LLM::Functions::Tooled {
    has $.service-style is rw = Whatever;
    has @.tools is rw = [];

    submethod bless(:$!service-style, :@!tools) {}

    multi method new($service-style = Whatever, @tools = Empty) {
        self.bless(:$service-style, :@tools)
    }

    multi method new(:s(:style(:$service-style)) = Whatever, :t(:@tools) = Empty) {
        self.bless(:$service-style, :@tools)
    }

    multi method synthesize(Str:D $prompt, *%args) {!!!}
    multi method synthesize(@prompts where @prompts.all ~~ Str:D, *%args) {
        self.synthesize(@prompts.join("\n"), |%args)
    }
}