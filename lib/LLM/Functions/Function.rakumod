use v6.d;

#===========================================================
# LLM Function class
#===========================================================

class LLM::Function does Callable {
    has &.func is required handles <name signature>;
    has $.llm-evaluator is required;
    has &.query-func = WhateverCode;

    submethod BUILD(:&!func, :$!llm-evaluator, :&!query-func) {}
    method new(:&func, :$llm-evaluator, :&query-func = WhateverCode) {
        self.bless(:&func, :$llm-evaluator, :&query-func)
    };
    method CALL-ME(|c) { &!func(|c) }
}

