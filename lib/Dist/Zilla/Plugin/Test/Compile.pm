use 5.008;
use strict;
use warnings;

package Dist::Zilla::Plugin::Test::Compile;
# ABSTRACT: common tests to check syntax of your modules

use Moose;
use Data::Section -setup;
with 'Dist::Zilla::Role::FileGatherer';

use Moose::Util::TypeConstraints;

# -- attributes

has fake_home     => ( is=>'ro', isa=>'Bool', default=>0 );
has skip          => ( is=>'ro', predicate=>'has_skip' ); # skiplist - a regex
has needs_display => ( is=>'ro', isa=>'Bool', default=>0 );
has fail_on_warning => ( is=>'ro', isa=>enum([qw(none author all)]), default=>'author' );
has bail_out_on_fail => ( is=>'ro', isa=>'Bool', default=>0 );

# -- public methods

sub gather_files {

    my ( $self , ) = @_;

    my $skip = ( $self->has_skip && $self->skip )
        ? sprintf( 'return if $found =~ /%s/;', $self->skip )
        : '# nothing to skip';

    my $home = ( $self->fake_home )
        ? ''
        : '# no fake requested ##';

    # Skip all tests if you need a display for this test and $ENV{DISPLAY} is not set
    my $needs_display = '';
    if ( $self->needs_display ) {
        $needs_display = <<'CODE';
BEGIN {
    if( not $ENV{DISPLAY} and not $^O eq 'MSWin32' ) {
        plan skip_all => 'Needs DISPLAY';
        exit 0;
    }
}
CODE
    }

    my $bail_out = $self->bail_out_on_fail
        ? 'BAIL_OUT("Compilation problems") if !Test::More->builder->is_passing;'
        : '';

    my $fail_on_warning = $self->fail_on_warning ne 'none'
        ? q{is(scalar(@warnings), 0, 'no warnings found');}
        : '';
    $fail_on_warning = 'if ($ENV{AUTHOR_TESTING} { ' . $fail_on_warning . ' }'
        if $self->fail_on_warning eq 'author';

    my $test_more_version = $self->bail_out_on_fail ? ' 0.94' : ' 0.88';

    require Dist::Zilla::File::InMemory;

    for my $file (qw( t/00-compile.t )){
        my $content = ${$self->section_data($file)};
        $content =~ s/COMPILETESTS_TESTMORE_VERSION/$test_more_version/g;
        $content =~ s/COMPILETESTS_SKIP/$skip/g;
        $content =~ s/COMPILETESTS_FAKE_HOME/$home/;
        $content =~ s/COMPILETESTS_NEEDS_DISPLAY/$needs_display/;
        $content =~ s/COMPILETESTS_BAIL_OUT_ON_FAIL/$bail_out/;
        $content =~ s/COMPILETESTS_FAIL_ON_WARNING/$fail_on_warning/;
        $content =~ s/ +$//gm;

        $self->add_file( Dist::Zilla::File::InMemory->new(
            name => $file,
            content => $content,
        ));
    }
}


no Moose;
__PACKAGE__->meta->make_immutable;
1;

=for Pod::Coverage::TrustPod
    gather_files


=head1 SYNOPSIS

In your dist.ini:

    [Test::Compile]
    skip      = Test$
    fake_home = 1
    needs_display = 1
    fail_on_warning = 1
    bail_out_on_fail = 1


=head1 DESCRIPTION

This is an extension of L<Dist::Zilla::Plugin::InlineFiles>, providing
the following files:

=over 4

=item * F<t/00-compile.t> - a standard test to check syntax of bundled modules

This test will find all modules and scripts in your dist, and try to
compile them one by one. This means it's a bit slower than loading them
all at once, but it will catch more errors.

We currently only check F<bin/>, F<script/> and F<scripts/> for scripts.

=back


This plugin accepts the following options:

=over 4

=item * skip: a regex to skip compile test for modules matching it. The
match is done against the module name (C<Foo::Bar>), not the file path
(F<lib/Foo/Bar.pm>).

=item * fake_home: a boolean to indicate whether to fake C<< $ENV{HOME} >>.
This may be needed if your module unilateraly creates stuff in homedir:
indeed, some cpantesters will smoke test your dist with a read-only home
directory. Default to false.

=item * needs_display: a boolean to indicate whether to skip the compile test
on non-Win32 systems when C<< $ENV{DISPLAY} >> is not set. Defaults to false.

=item * fail_on_warning: a string to indicate when to add a test for
warnings during compilation checks. Possible values are:

=over 4

=item * none: do not check for warnings

=item * author: check for warnings only when AUTHOR_TESTING is set
(default, and recommended)

=item * all: always test for warnings (not recommended, as this can prevent
installation of modules when upstream dependencies exhibit warnings in a new
Perl release)

=back

=item * bail_out_on_fail: a boolean to indicate whether the test will BAIL_OUT
of all subsequent tests when compilation failures are encountered. Defaults to false.

=back



=head1 SEE ALSO

L<Test::NeedsDisplay>

You can also look for information on this module at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dist-Zilla-Plugin-Test-Compile>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dist-Zilla-Plugin-Test-Compile>

=item * Open bugs

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dist-Zilla-Plugin-Test-Compile>

=item * Git repository

L<http://github.com/jquelin/dist-zilla-plugin-test-compile.git>.

=back


=cut

__DATA__
___[ t/00-compile.t ]___
#!perl

use strict;
use warnings;

use Test::MoreCOMPILETESTS_TESTMORE_VERSION;

COMPILETESTS_NEEDS_DISPLAY

use File::Find;
use File::Temp qw{ tempdir };
use Capture::Tiny qw{ capture };

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

sub _find_scripts {
    my $dir = shift @_;

    my @found_scripts = ();
    find(
      sub {
        return unless -f;
        my $found = $File::Find::name;
        COMPILETESTS_SKIP
        open my $FH, '<', $_ or do {
          note( "Unable to open $found in ( $! ), skipping" );
          return;
        };
        my $shebang = <$FH>;
        return unless $shebang =~ /^#!.*?\bperl\b\s*$/;
        push @found_scripts, $found;
      },
      $dir,
    );

    return @found_scripts;
}

my @scripts;
do { push @scripts, _find_scripts($_) if -d $_ }
    for qw{ bin script scripts };

{
    # fake home for cpan-testers
    COMPILETESTS_FAKE_HOME local $ENV{HOME} = tempdir( CLEANUP => 1 );

    my @warnings;
    for my $module (sort @modules)
    {
        my ($stdout, $stderr, $exit) = capture {
            system($^X, '-Ilib', '-e', qq{require $module; print "$module ok"});
        };
        like($stdout, qr/^\s*$module ok/s, "$module loaded ok" );
        warn $stderr if $stderr;
        push @warnings, $stderr if $stderr;
    }

    COMPILETESTS_FAIL_ON_WARNING

    SKIP: {
        eval "use Test::Script 1.05; 1;";
        skip "Test::Script needed to test script compilation", scalar(@scripts) if $@;
        foreach my $file ( @scripts ) {
            my $script = $file;
            $script =~ s!.*/!!;
            script_compiles( $file, "$script script compiles" );
        }
    }
    COMPILETESTS_BAIL_OUT_ON_FAIL
}

done_testing;
