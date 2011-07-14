use strict;
use warnings;
use Test::Base;

use Encode;
use Encode::DoubleEncodedUTF8;

filters {
    input => [ 'chomp', 'string' ],
    expected => [ 'chomp', 'string' ]
};

sub string {
    my $str = shift;
    eval qq("$str");
}

plan tests => 1 * blocks;

run {
    my $block = shift;
    is decode("utf-8-de", $block->input), $block->expected, $block->name;
}

__END__

=== U+5BAE followed by double encoded U+5BAE
--- input
\xe5\xae\xae\xc3\xa5\xc2\xae\xc2\xae
--- expected
\x{5bae}\x{5bae}

=== Unicode + UTF-8 (double)
--- input
\xe5\xae\xae\xc3\xa5\xc2\xae\xc2\xae\xe5\xae\xae\xc3\xa5\xc2\xae\xc2\xae
--- expected
\x{5bae}\x{5bae}\x{5bae}\x{5bae}

=== 2 x double encoded U+0100
--- input
\xc3\x84\xc2\x80\xc3\x84\xc2\x80
--- expected
\x{100}\x{100}

=== 2 x double encoded U+5BAE
--- input
\xc3\xa5\xc2\xae\xc2\xae\xc3\xa5\xc2\xae\xc2\xae
--- expected
\x{5bae}\x{5bae}

=== 2 x double encoded U+10000
--- input
\xc3\xb0\xc2\x90\xc2\x80\xc2\x80\xc3\xb0\xc2\x90\xc2\x80\xc2\x80
--- expected
\x{10000}\x{10000}

=== Double encoded U+5BAE followed by U+00A5
--- input
\xc3\xa5\xc2\xae\xc2\xae\xc2\xa5
--- expected
\x{5bae}\x{a5}

=== U+00C0 followed by double encoded U+0100
--- input
\xc3\x80\xc3\x84\xc2\x80
--- expected
\x{c0}\x{100}

=== U+00C3 followed by double encoded U+5BAE
--- input
\xc3\x83\xc3\xa5\xc2\xae\xc2\xae
--- expected
\x{00c3}\x{5bae}

=== Dodgy Latin-1
--- input
Hello LÃ©on
--- expected
Hello L\x{e9}on

=== Safe latin-1
--- input
Hello Léon
--- expected
Hello L\x{e9}on

=== Safe latin-1 + dodgy utf-8
--- input
Léon \xe5\xae\xae\xc3\xa5\xc2\xae\xc2\xae
--- expected
L\x{e9}on \x{5bae}\x{5bae}
