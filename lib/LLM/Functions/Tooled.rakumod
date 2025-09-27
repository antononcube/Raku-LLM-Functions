use v6.d;

use LLM::Functions::Evaluator;

class LLM::Functions::Tooled
        is LLM::Functions::Evaluator {
    has @.tools is rw = [];

    submethod bless(:$conf, :$formatron, :@!tools) {
        nextwith(:$conf, :$formatron)
    }

    method new(:c(:$conf) = Whatever, :f(:form(:$formatron)) = 'Str', :t(:@tools) = Empty) {
        self.bless(:$conf, :$formatron, :@tools)
    }

    method normalize-tool-spec(%spec) {!!!}

    method extract-tool-requests(%assistant-content) {!!!}

    multi method eval(@texts, *%args) {!!!}
}