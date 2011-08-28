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

THIS MODULE IS DEPRECATED, PLEASE USE
L<Dist::Zilla::Plugin::Test::Compile> INSTEAD. IT MAY BE REMOVED AT A
LATER TIME (but not before 2012-08-27).

In the meantime, it will continue working - although with a warning.
Refer to the replacement for the actual documentation.

