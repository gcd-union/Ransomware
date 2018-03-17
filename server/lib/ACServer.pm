package ACServer;
use Mojo::Base 'Mojolicious';

# This method will run once at server start
sub startup {
    my $self = shift;

    # Documentation browser under "/perldoc"
    $self->plugin('PODRenderer');

    # Router
    my $r = $self->routes;

    # Normal route to controller
    $r->route('/acrypt/regkey')
      ->to( controller => 'a_c_main', action => 'regkey' );
    $r->route('/acrypt/getkey')
      ->to( controller => 'a_c_main', action => 'getkey' );
}

1;
