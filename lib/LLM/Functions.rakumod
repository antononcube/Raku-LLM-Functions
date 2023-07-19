use v6.d;

use JSON::Fast;
use HTTP::Tiny;

use WWW::OpenAI;
use WWW::OpenAI::Models;
use WWW::OpenAI::TextCompletions;
use WWW::OpenAI::ChatCompletions;

use WWW::PaLM;
use WWW::PaLM::Models;
use WWW::PaLM::GenerateText;
use WWW::PaLM::GenerateMessage;

use LLM::Functions::Configuration;

unit module LLM::Functions;

#===========================================================
#| LLM configuration creation and retrieval.
our proto llm-configuration(|) is export {*}

multi sub llm-configuration(Str $spec) {
   given $spec.lc {
       when 'openai' {
           my $obj =
                   LLM::Functions::Configuration .= new(
                   name => 'openai',
                   module => 'WWW::OpenAI',
                   model => 'text-davinci-003',
                   evaluator => &OpenAITextCompletion,
                   temperature => 0.8,
                   totalProbabilityCutoff => 0.03,
                   prompts => Empty,
                   promptDelimiter => ' ');

           $obj
       }
   }
}

#===========================================================
#| Represents a template for a large language model(LLM) prompt.
our proto llm-function(|) is export {*}

multi sub llm-functionl(Str $prompt, llm-evaluator => WhateverCode) {

}
