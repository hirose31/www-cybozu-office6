#!perl

if (!require Test::Perl::Critic) {
    Test::More::plan(
        skip_all => "Test::Perl::Critic required for testing PBP compliance"
    );
}
import Test::Perl::Critic (-exclude => [
    'BuiltinFunctions::ProhibitStringyEval',
   ]);
Test::Perl::Critic::all_critic_ok();
