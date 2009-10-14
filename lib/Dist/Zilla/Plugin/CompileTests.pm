use strict;
use warnings;

package Dist::Zilla::Plugin::CompileTests;
# ABSTRACT: common tests to check syntax of your modules

use Moose;
extends 'Dist::Zilla::Plugin::InlineFiles';
with    'Dist::Zilla::Role::FileMunger';


# -- attributes

# skiplist - a regex
has skip => ( is=>'ro', predicate=>'has_skip' );


# -- public methods

# called by the filemunger role
sub munge_file {
    my ($self, $file) = @_;

    return unless $file->name eq 't/00-compile.t';

    my $replacement = ( $self->has_skip && $self->skip )
        ? sprintf( 'return if $found =~ /%s/;', $self->skip )
        : '# nothing to skip';

    # replace the string in the file
    my $content = $file->content;
    $content =~ s/COMPILETESTS_SKIP/$replacement/;
    $file->content( $content );
}


no Moose;
__PACKAGE__->meta->make_immutable;
1;

=begin Pod::Coverage

munge_file

=end Pod::Coverage


=head1 SYNOPSIS

In your dist.ini:

    [CompileTests]
    skip = Test$

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
    
is( qx{ $^X -Ilib -M$_ -e "print '$_ ok'" }, "$_ ok", "$_ loaded ok" )
    for sort @modules;
    
SKIP: {
    eval "use Test::Script; 1;";
    skip "Test::Script needed to test script compilation", scalar(@scripts) if $@;
    foreach my $file ( @scripts ) {
        my $script = $file;
        $script =~ s!.*/!!;
        script_compiles_ok( $file, "$script script compiles" );
    }
}
