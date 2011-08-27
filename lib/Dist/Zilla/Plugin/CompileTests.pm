#
# This file is part of Dist-Zilla-Plugin-Test-Compile
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
{
  $Dist::Zilla::Plugin::CompileTests::VERSION = '1.112391';
}
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


=pod

=head1 NAME

Dist::Zilla::Plugin::CompileTests - (DEPRECATED) common tests to check syntax of your modules

=head1 VERSION

version 1.112391

=head1 SYNOPSIS

THIS MODULE IS DEPRECATED, PLEASE USE
L<Dist::Zilla::Plugin::Test::Compile> INSTEAD. IT MAY BE REMOVED AT A
LATER TIME (but not before 2012-08-27).

In the meantime, it will continue working - although with a warning.
Refer to the replacement for the actual documentation.

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

