use v6.d;

use Hash::Merge;
use LLM::Functions::Configuration;
use Text::SubParsers;

class LLM::Functions::Evaluator {

    has $.conf is rw = Whatever;
    has $.formatron is rw = 'Str';

    #-------------------------------------------------------
    method clone { nextwith :conf($!conf.clone), |%_ }

    #-------------------------------------------------------
    method prompt-texts-combiner($prompt, @texts, *%args) {
        return [$prompt, |@texts].join($.conf.prompt-delimiter).trim;
    }

    #-------------------------------------------------------
    method get-formatron($spec) {
        return Nil unless $spec;
        return do given $spec {
            when Str:U { Text::SubParsers::exact-parser(:$spec) }
            when $_ ~~ Str:D && $_ eq 'Str' { Nil }
            when $_ ~~ Text::SubParsers::Core { $spec }
            default { Text::SubParsers::exact-parser(:$spec) }
        }
    }

    #-------------------------------------------------------
    method post-process($res is copy, :$form = Whatever) {

        $res = do if $res ~~ Iterable && $res.elems == 1 {
            $res.head;
        } else {
            $res;
        }

        my $reformater =
                do if $form.isa(Whatever) || $form.isa(WhateverCode) {
                    self.get-formatron($!formatron);
                } else {
                    self.get-formatron($form);
                };

        with $reformater {
            return $reformater.process($res);
        }
        return $res;
    }

    #-------------------------------------------------------
    multi method eval(Str $text, *%args) {
        return self.eval([$text,], |%args);
    }

    multi method eval(@texts, *%args) {

        # To echo or not
        my $echo = %args<echo> // False;

        # Clone configuration
        # We clone the configuration because some changes of the prompts are done
        # before sending the evaluation request to LLM service.
        my $confLocal = self.conf.clone;

        note "Configuration : {$confLocal.Hash.raku}" if $echo;

        # Load module
        my $packageName = $confLocal.module;

        my Bool $no-package = False;
        try require ::($packageName);
        if ::($packageName) ~~ Failure {
            $no-package = True
        }

        CATCH {
            if $no-package { warn "Cannot load package named $packageName."; }
        }

        note "Loaded : $packageName"  if $echo;

        # Find known parameters
        my @knownParamNames = $confLocal.function.candidates.map({ $_.signature.params.map({ $_.usage-name }) }).flat;

        note "Known param mames : {@knownParamNames.raku}" if $echo;

        # Make all named parameters hash
        my %args2 = merge-hash($confLocal.Hash, %args);

        # Handling the argument renaming in a more bureaucratic manner
        for $confLocal.argument-renames.kv -> $k, $v {
            %args2{$v} = %args2{$v} // %args2{$k} // Whatever;
        }

        # Make "full" prompt
        my $prompt = $confLocal.prompts.join($confLocal.prompt-delimiter).trim;

        note 'Full prompt : ', $prompt.raku if $echo;

        my @messages = self.prompt-texts-combiner($prompt, @texts);

        note 'Messages : ', @messages.raku if $echo;

        %args2 = %args2.grep({ $_.key ∉ <prompts> && $_.key ∈ @knownParamNames }).Hash;

        # Should this check be here?
        if (%args2<examples>:exists) && (@messages.grep(* ~~ Pair).Hash<examples>:exists) {
            %args2 .= grep({ $_.key ne 'examples' })
        }

        note 'LLM function named arguments : ', %args2.raku if $echo;

        # Invoke the LLM function
        my $res = $confLocal.function.( @messages, |%args2);

        note 'LLM response : ', $res if $echo;

        return self.post-process($res, form => %args<form> // Whatever);
    }
}