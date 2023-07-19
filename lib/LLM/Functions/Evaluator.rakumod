use v6.d;

use Hash::Merge;
use LLM::Functions::Configuration;

class LLM::Functions::Evaluator {

    has $.conf is rw = Whatever;

    method prompt-texts-combiner($prompt, @texts) {
        return [$prompt, |@texts].join($.conf.prompt-delimiter);
    }

    multi method eval(Str $text, *%args) {
        my $res = self.eval([$text,], |%args);
        return do if $res ~~ Iterable && $res.elems == 1 {
            $res.head;
        } else {
            $res;
        }
    }

    multi method eval(@texts, *%args) {

        # To echo or not
        my $echo = %args<echo> // False;

        if $echo {
            note "Configuration : {self.conf.Hash.raku}";
            #{.note for self.conf.Hash};
        }

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

        if $echo {
            note "Loaded : $packageName";
        }

        # Find known parameters
        my @knownParamNames = $!conf.function.candidates.map({ $_.signature.params.map({ $_.usage-name }) }).flat;

        if $echo {
            note "Known param mames : {@knownParamNames.raku}";
        }

        # Make all named parameters hash
        my %args2 = merge-hash($!conf.Hash, %args);

        # Handling the argument renaming in a more bureaucratic manner
        for $.conf.argument-renames.kv -> $k, $v {
            %args2{$v} = %args2{$v} // %args2{$k} // Whatever;
        }

        # Make "full" prompt
        my $prompt = $!conf.prompts.join($.conf.prompt-delimiter);

        if $echo {
            note 'Full prompt : ', $prompt.raku;
        }

        my @messages = self.prompt-texts-combiner($prompt, @texts);

        if $echo {
            note 'Messages : ', @messages.raku;
        }

        # Invoke the LLM function
        return $!conf.function.( @messages,
                |%args2.grep({ $_.key ∉ <prompts> && $_.key ∈ @knownParamNames }).Hash
        );
    }
}

class LLM::Functions::ChatEvaluator
        is LLM::Functions::Evaluator {

    method prompt-texts-combiner($prompt, @texts) {
        return ['system' => $prompt, |('user' X=> @texts)];
    }
}