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
        return [$prompt, |@texts].join($.conf.prompt-delimiter);
    }

    #-------------------------------------------------------
    method get-formatron($spec) {
        return Nil unless $spec;
        return do given $spec {
            when Str:U { Text::SubParsers::get-parser(:$spec) }
            when $_ ~~ Str:D && $_ eq 'Str' { Nil }
            when $_ ~~ Text::SubParsers::Core { $spec }
            default { Text::SubParsers::get-parser(:$spec) }
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

        note "Configuration : {self.conf.Hash.raku}" if $echo;

        # Load module
        my $packageName = $.conf.module;

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
        my @knownParamNames = $!conf.function.candidates.map({ $_.signature.params.map({ $_.usage-name }) }).flat;

        note "Known param mames : {@knownParamNames.raku}" if $echo;

        # Make all named parameters hash
        my %args2 = merge-hash($!conf.Hash, %args);

        # Handling the argument renaming in a more bureaucratic manner
        for $.conf.argument-renames.kv -> $k, $v {
            %args2{$v} = %args2{$v} // %args2{$k} // Whatever;
        }

        # Make "full" prompt
        my $prompt = $!conf.prompts.join($.conf.prompt-delimiter);

        note 'Full prompt : ', $prompt.raku if $echo;

        my @messages = self.prompt-texts-combiner($prompt, @texts);

        note 'Messages : ', @messages.raku if $echo;

        %args2 = %args2.grep({ $_.key ∉ <prompts> && $_.key ∈ @knownParamNames }).Hash;

        note 'LLM function named arguments : ', %args2.raku if $echo;

        # Invoke the LLM function
        my $res = $!conf.function.( @messages, |%args2);

        note 'LLM response : ', $res if $echo;

        return self.post-process($res, form => %args<form> // Whatever);
    }
}

#===========================================================
class LLM::Functions::ChatEvaluator
        is LLM::Functions::Evaluator {

    submethod TWEAK {
        without self.conf { self.conf = Whatever; }
        without self.formatron { self.formatron = 'Str'; }
    }

    has Str $.system-role is rw = 'system';

    method prompt-texts-combiner($prompt, @texts) {
        my @messages = do given @texts {
            when $_.all ~~ Str {
                ('user' X=> @texts);
            }
            when $_.all ~~ Pair {
                @texts;
            }

            when $_.all ~~ Map {
                @texts.map({ $_<role> => $_<content> }).Array;
            }

            default {
                die 'Unknown form of the second argument (@texts).';
            }
        };

        if $prompt {
            return [$!system-role => $prompt, |@messages];
        } else {
            return @messages;
        }
    }
}