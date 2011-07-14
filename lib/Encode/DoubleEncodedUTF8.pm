package Encode::DoubleEncodedUTF8;

use strict;
use base qw( Encode::Encoding );
use Carp ();
use Encode 2.12 ();

our $VERSION = '0.05';

__PACKAGE__->Define('utf-8-de');

my $UTF8_double_encoded = qr/
    \xC3 (?: [\x82-\x9F] \xC2 [\x80-\xBF]                                    # U+0080 - U+07FF
           |  \xA0       \xC2 [\xA0-\xBF] \xC2 [\x80-\xBF]                   # U+0800 - U+0FFF
           | [\xA1-\xAC] \xC2 [\x80-\xBF] \xC2 [\x80-\xBF]                   # U+1000 - U+CFFF
           |  \xAD       \xC2 [\x80-\x9F] \xC2 [\x80-\xBF]                   # U+D000 - U+D7FF
           | [\xAE-\xAF] \xC2 [\x80-\xBF] \xC2 [\x80-\xBF]                   # U+E000 - U+FFFF
           |  \xB0       \xC2 [\x90-\xBF] \xC2 [\x80-\xBF] \xC2 [\x80-\xBF]  # U+010000 - U+03FFFF
           | [\xB1-\xB3] \xC2 [\x80-\xBF] \xC2 [\x80-\xBF] \xC2 [\x80-\xBF]  # U+040000 - U+0FFFFF
           |  \xB4       \xC2 [\x80-\x8F] \xC2 [\x80-\xBF] \xC2 [\x80-\xBF]  # U+100000 - U+10FFFF
         )
/x;

my %MAP = map { pack('C', $_) => pack('C', $_ ^ 0x40) } (0x82..0xB4);

sub decode {
    my($obj, $buf, $chk) = @_;

    utf8::downgrade($buf, 1)
      or Carp::croak('Wide characters in string');

    $buf =~ s!($UTF8_double_encoded)!
        my $s = $1;
        $s =~ s/[\xC2-\xC3]//g;
        substr $s, 0, 1, $MAP{substr $s, 0, 1};
        $s;
    !xgeo;

    $_[1] = '' if $chk; # this is what in-place edit means
    Encode::decode_utf8($buf);
}

sub encode {
    Carp::croak("utf-8-de doesn't support encode() ... Why do you want to do that?");
}

1;

=for stopwords utf-8 UTF-8

=head1 NAME

Encode::DoubleEncodedUTF8 - Fix double encoded UTF-8 bytes to the correct one

=head1 SYNOPSIS

  use Encode;
  use Encode::DoubleEncodedUTF8;

  my $dodgy_utf8 = "Some byte strings from the web/DB with double-encoded UTF-8 bytes";
  my $fixed = decode("utf-8-de", $dodgy_utf8); # Fix it

=head1 WARNINGS

Use this module B<only> for testing, debugging, data recovery and
working around with buggy software you I<can't> fix.

B<Do not> use this module in your production code just to I<work
around> bugs in the code you I<can> fix. This module is slow, and not
perfect and may break the encodings if you run against correctly
encoded strings. See L<perlunitut> for more details.

=head1 DESCRIPTION

Encode::DoubleEncodedUTF8 adds a new encoding C<utf-8-de> and fixes
double encoded utf-8 bytes found in the original bytes to the correct
Unicode entity.

The double encoded utf-8 frequently happens when strings with UTF-8
flag and without are concatenated, for instance:

  my $string = "L\x{e9}on";   # latin-1
  utf8::upgrade($string);
  my $bytes  = "L\xc3\xa9on"; # utf-8

  my $dodgy_utf8 = encode_utf8($string . " " . $bytes); # $bytes is now double encoded

  my $fixed = decode("utf-8-de", $dodgy_utf8); # "L\x{e9}on L\x{e9}on";

See L<encoding::warnings> for more details.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<encoding::warnings>, L<Test::utf8>

=cut
