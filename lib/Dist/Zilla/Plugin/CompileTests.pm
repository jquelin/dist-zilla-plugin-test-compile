use 5.008;
use strict;
use warnings;

package Dist::Zilla::Plugin::CompileTests;
# ABSTRACT: (DEPRECATED) common tests to check syntax of your modules

use Moose;
extends 'Dist::Zilla::Plugin::Test::Compile';

use namespace::autoclean;

before register_component => sub {
  warn "!!! [CompileTests] is deprecated and may be removed in a future; replace it with [Test::Compile]\n";
};

no Moose;
__PACKAGE__->meta->make_immutable;
1;

=head1 SYNOPSIS

PLEASE USE L<Dist::Zilla::Plugin::Test::Compile> instead.

In your dist.ini:

    [Test::Compile]
    skip      = Test$
    fake_home = 1
    needs_display = 1


=head1 DESCRIPTION

This is an extension of L<Dist::Zilla::Plugin::InlineFiles>, providing
the following files:

=over 4

=item * t/00-compile.t - a standard test to check syntax of bundled modules

This test will find all modules and scripts in your dist, and try to
compile them one by one. This means it's a bit slower than loading them
all at once, but it will catch more errors.

=back


This plugin accepts the following options:

=over 4

=item * skip: a regex to skip compile test for modules matching it. The
match is done against the module name (C<Foo::Bar>), not the file path
(F<lib/Foo/Bar.pm>).

=item * fake_home: a boolean to indicate whether to fake $ENV{HOME}.
This may be needed if your module unilateraly creates stuff in homedir:
indeed, some cpantesters will smoke test your dist with a read-only home
directory. Default to false.

=item * needs_display: a boolean to indicate whether to skip the compile test
on non-win32 systems when $ENV{DISPLAY} is not set. Default to false.

=back

=cut
__END__
