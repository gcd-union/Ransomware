use strict;
use warnings;
use File::Find;
use File::HomeDir;
use Crypt::Mode::CBC;
use File::Slurp;
use LWP::UserAgent;
use File::Spec;
use HTTP::Request;
use JSON::PP 'decode_json';
use Digest::MD5 'md5_hex';
use autodie;
use constant AUTO_REMOTE_KEY => 1;
use constant AUTOKEY_URL     => 'http://localhost:3000/acrypt/getkey/?id=%id%';
use feature 'say';
my $ikey;
input:

if (AUTO_REMOTE_KEY) {
    say 'Using remote autokey';
    my $id =
      read_file( File::Spec->catfile( File::HomeDir->my_home, '.cid.txt' ) );
    my $requrl = AUTOKEY_URL;
    $requrl =~ s/%id%/$id/;
    my $req  = HTTP::Request->new( GET => $requrl );
    my $ua   = LWP::UserAgent->new;
    my $res  = $ua->request($req);
    my $stat = $res->status_line;
    my $cont = decode_json( $res->content );
    my $reas = ( exists $cont->{reason} ) ? $cont->{reason} : "Unknown";
    $res->is_success || die <<EOF;
Error: remote key fetch failure: $stat
Reason: $reas
Please contact support
CID: $id
EOF
    $ikey = decode_json( $res->content )->{key};
}
else {
    print "Key>";
    chomp( $ikey = <STDIN> );
}
my $c = Crypt::Mode::CBC->new('AES');
my $chk =
  read_file( File::Spec->catfile( File::HomeDir->my_home, '.keycheck.txt' ),
    binmode => ':raw' );
my ( $key, $iv ) = split( ':', $ikey );
my $kwh =
  read_file( File::Spec->catfile( File::HomeDir->my_home, '.kwhash.txt' ) );

if ( md5_hex( eval { no warnings; $c->decrypt( $chk, $key, $iv ) } ) ne $kwh ) {
    say('Incorrect key');
    goto 'input';
}
find(
    sub {
        my $f = $_;
        /^(.*)\.acrypt$/ || return;
        my $inp = read_file( $f, binmode => ':raw' );
        printf( "%s.acrypt => %s\n", $1, $1 );
        write_file( $1, { binmode => ':raw' }, $c->decrypt( $inp, $key, $iv ) );
    },
    File::HomeDir->my_home,
);
