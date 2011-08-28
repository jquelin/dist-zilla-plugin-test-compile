
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Dist::Zilla::Tester" => 0,
    "File::Find" => 0,
    "File::Temp" => 0,
    "Module::Build" => "0.3601",
    "Path::Class" => 0,
    "Test::More" => "0.88"
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "common tests to check syntax of your modules",
  "dist_author" => [
    "Jerome Quelin"
  ],
  "dist_name" => "Dist-Zilla-Plugin-Test-Compile",
  "dist_version" => "1.112400",
  "license" => "perl",
  "module_name" => "Dist::Zilla::Plugin::Test::Compile",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Data::Section" => 0,
    "Dist::Zilla::File::InMemory" => 0,
    "Dist::Zilla::Role::FileGatherer" => 0,
    "Moose" => 0,
    "namespace::autoclean" => 0,
    "perl" => "5.008",
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
