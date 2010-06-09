use 5.008;
use strict;
use warnings;

package Dist::Zilla::Plugin::CompileTests;
# ABSTRACT: common tests to check syntax of your modules

use Moose;
extends 'Dist::Zilla::Plugin::InlineFiles';
with    'Dist::Zilla::Role::FileMunger';


# -- attributes

has fake_home => ( is=>'ro', predicate=>'has_fake_home' );
has skip      => ( is=>'ro', predicate=>'has_skip' ); # skiplist - a regex


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

    # replace strings in the file
    my $content = $file->content;
    $content =~ s/COMPILETESTS_SKIP/$skip/;
    $content =~ s/COMPILETESTS_FAKE_HOME/$home/;
    $file->content( $content );
}


no Moose;
__PACKAGE__->meta->make_immutable;
1;

=for Pod::Coverage::TrustPod
    munge_file


=head1 SYNOPSIS

In your dist.ini:

    [CompileTests]
    skip      = Test$
    fake_home = 1


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

=back



=head1 SEE ALSO

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


=cut

__DATA__
___[ t/00-compile.t ]___
#!perl

use strict;
use warnings;

use Test::More;
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

my @scripts = glob "bin/*";

plan tests => scalar(@modules) + scalar(@scripts);

{
    # fake home for cpan-testers
    COMPILETESTS_FAKE_HOME local $ENV{HOME} = tempdir( CLEANUP => 1 );

    like( qx{ $^X -Ilib -e "use $_; print '$_ ok'" }, qr/^\s*$_ ok/s, "$_ loaded ok" )
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
