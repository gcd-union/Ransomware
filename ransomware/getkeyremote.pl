use LWP::UserAgent;
use HTTP::Request;
use JSON::PP;
use strict;
use warnings;
use autodie;
use feature 'say';
use constant CNC_REMOTE_KEY_URL =>
  'http://localhost:3000/acrypt/getkey/?id=%id%';
my $ua = LWP::UserAgent->new;

foreach my $id (@ARGV) {
    my $url = CNC_REMOTE_KEY_URL;
    $url =~ s/%id%/$id/;
    my $req = HTTP::Request->new( GET => $url );
    my $res = $ua->request($req);
    $res->is_success || die 'Remote server error';
    say decode_json( $res->content )->{key};
}
