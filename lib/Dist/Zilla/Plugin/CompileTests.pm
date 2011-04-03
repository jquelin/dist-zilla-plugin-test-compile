#
# This file is part of Dist-Zilla-Plugin-CompileTests
#
# This software is copyright (c) 2009 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use 5.008;
use strict;
use warnings;

package Dist::Zilla::Plugin::CompileTests;
BEGIN {
  $Dist::Zilla::Plugin::CompileTests::VERSION = '1.110930';
}
# ABSTRACT: common tests to check syntax of your modules

use Moose;
extends 'Dist::Zilla::Plugin::InlineFiles';
with    'Dist::Zilla::Role::FileMunger';


# -- attributes

has fake_home     => ( is=>'ro', predicate=>'has_fake_home' );
has skip          => ( is=>'ro', predicate=>'has_skip' ); # skiplist - a regex
has needs_display => ( is=>'ro', predicate=>'has_needs_display' );

# -- public methods

# called by the filemunger role
sub munge_file {
    my ($self, $file) = @_;

    return unless $file->name eq 't/00-compile.t';

    my $skip = ( $self->has_skip && $self->skip )
        ? sprintf( 'return if $found =~ /%s/;', $self->skip )
        : '# nothing to skip';

    my $home = ( $self->has_fake_home && $self->fake_home )
        ? ''
        : '# no fake requested ##';

    # Skip all tests if you need a display for this test and $ENV{DISPLAY} is not set
    my $needs_display = '';
    if ( $self->has_needs_display && $self->needs_display ) {
        $needs_display = <<'CODE';
BEGIN {
    if( not $ENV{DISPLAY} and not $^O eq 'MSWin32' ) {
        plan skip_all => 'Needs DISPLAY';
        exit 0;
    }
}
CODE
    }

    # replace strings in the file
    my $content = $file->content;
    $content =~ s/COMPILETESTS_SKIP/$skip/g;
    $content =~ s/COMPILETESTS_FAKE_HOME/$home/;
    $content =~ s/COMPILETESTS_NEEDS_DISPLAY/$needs_display/;
    $file->content( $content );
}


no Moose;
__PACKAGE__->meta->make_immutable;
1;




=pod

=head1 NAME

Dist::Zilla::Plugin::CompileTests - common tests to check syntax of your modules

=head1 VERSION

version 1.110930

=head1 SYNOPSIS

In your dist.ini:

    [CompileTests]
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

=for Pod::Coverage::TrustPod munge_file

=head1 SEE ALSO

L<Test::NeedsDisplay>

You can also look for information on this module at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dist-Zilla-Plugin-CompileTests>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dist-Zilla-Plugin-CompileTests>

=item * Open bugs

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dist-Zilla-Plugin-CompileTests>

=item * Git repository

L<http://github.com/jquelin/dist-zilla-plugin-compiletests.git>.

=back

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__DATA__
___[ t/00-compile.t ]___
#!perl

use strict;
use warnings;

use Test::More;

COMPILETESTS_NEEDS_DISPLAY

use File::Find;
use File::Temp qw{ tempdir };

my @modules;
find(
  sub {
    return if $File::Find::name !~ /\.pm\z/;
    my $found = $File::Find::name;
    $found =~ s{^lib/}{};
    $found =~ s{[/\\]}{::}g;
    $found =~ s/\.pm$//;
    COMPILETESTS_SKIP
    push @modules, $found;
  },
  'lib',
);

my @scripts;
if ( -d 'bin' ) {
    find(
      sub {
        return unless -f;
        my $found = $File::Find::name;
        COMPILETESTS_SKIP
        push @scripts, $found;
      },
      'bin',
    );
}

my $plan = scalar(@modules) + scalar(@scripts);
$plan ? (plan tests => $plan) : (plan skip_all => "no tests to run");

{
    # fake home for cpan-testers
    COMPILETESTS_FAKE_HOME local $ENV{HOME} = tempdir( CLEANUP => 1 );

    like( qx{ $^X -Ilib -e "require $_; print '$_ ok'" }, qr/^\s*$_ ok/s, "$_ loaded ok" )
        for sort @modules;

    SKIP: {
        eval "use Test::Script 1.05; 1;";
        skip "Test::Script needed to test script compilation", scalar(@scripts) if $@;
        foreach my $file ( @scripts ) {
            my $script = $file;
            $script =~ s!.*/!!;
            script_compiles( $file, "$script script compiles" );
        }
    }
}
