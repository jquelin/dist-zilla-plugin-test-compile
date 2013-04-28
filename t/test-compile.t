#!perl

use strict;
use warnings;

use Dist::Zilla::Tester;
use Path::Class;
use Cwd;
use Test::More tests => 1;

# build fake dist
my $tzil = Dist::Zilla::Tester->from_config({
    dist_root => dir(qw(t test-compile)),
});
my $cwd = getcwd;
chdir $tzil->tempdir->subdir('source');
$tzil->build;

my $dir = $tzil->tempdir->subdir('build');
ok( -e file($dir, 't', '00-compile.t'), 'test created');

chdir $cwd;
