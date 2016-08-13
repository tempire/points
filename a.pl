use Mojo::Base -strict;
use Mojo::Util qw/ slurp spurt /;
use Data::MessagePack;

my $data = slurp 'competitors.json';
my $mp = Data::MessagePack->new;
spurt $mp->pack($data) => 'competitors.messagepack';
