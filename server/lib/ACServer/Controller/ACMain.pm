package ACServer::Controller::ACMain;
use autodie;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::JSON qw(encode_json decode_json);
use FindBin;
use File::Slurp;

sub regkey {
    my $self     = shift;
    my $json     = JSON::PP->new->ascii->pretty;
    my $key      = $self->param('key');
    my $cid      = $self->param('id');
    my $btc_addr = 'DUMMY';
    my $data     = {
        key      => $key,
        paid     => \0,
        btc_addr => $btc_addr,
    };
    FindBin::again();
    my $confpath = $FindBin::Bin . '/../ackeys.json';
    my $jkeys;

    if ( -f $confpath ) {
        my $inpdat = read_file($confpath);
        my $keys   = decode_json($inpdat);
        $keys->{$cid} = $data;
        $jkeys = $json->encode($keys);
    }
    else {
        $jkeys = $json->encode( { $cid => $data } );
    }
    write_file( $confpath, $jkeys );
    $self->render( json => { btcaddr => $btc_addr } );
}

sub getkey {
    my $c        = shift;
    my $confpath = "$FindBin::Bin/../ackeys.json";
    my $inpdata  = read_file($confpath);
    my $data     = decode_json($inpdata);
    my $cid      = $c->param('id');
    if ( exists $data->{$cid} ) {
        my $cd = $data->{$cid};
        if ( ${ $cd->{paid} } ) {
            $c->render( json => { key => $cd->{key} } );
            return;
        }
        else {
            $c->res->code(403);
            $c->render( json =>
                  { reason => "Not paid, please pay to " . $cd->{btc_addr} } );
        }
    }
    else {
        $c->res->code(404);
        $c->render( json => { reason => "ID not found" } );
    }
}
1;
