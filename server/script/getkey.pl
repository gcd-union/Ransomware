#!/usr/bin/perl
use FindBin '$Bin';
use File::Slurp;
use JSON::PP qw(encode_json decode_json);
my $json = read_file("$Bin/../ackeys.json");
my $keys = decode_json($json);
my $cid  = $ARGV[0];
say $keys->{$cid}->{key};
