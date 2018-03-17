#!/usr/bin/perl
use FindBin '$Bin';
use JSON::PP;
use File::Slurp;
use strict;
use warnings;
use autodie;
my $json  = JSON::PP->new->ascii->pretty;
my $jkeys = read_file("$Bin/../ackeys.json");
my $keys  = $json->decode($jkeys);
foreach my $id (@ARGV) {
    use feature 'say';
    $keys->{$id}->{paid} = \1;
}
$jkeys = $json->encode($keys);
write_file( "$Bin/../ackeys.json", $jkeys );
