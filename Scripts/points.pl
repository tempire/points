use Mojo::Base -strict;
use Mojo::UserAgent;
use Data::Dumper;
use JSON::XS qw/ encode_json decode_json /;
use Mojo::Util qw/ spurt /;
use experimental qw/ signatures postderef current_sub /;

my $ua = Mojo::UserAgent->new;

my @alphabet = split '' => 'abcdefghijklmnopqrstuvwxyz';

my @competitor_ids;
my %competitors;
my @ends;

my $max          = 10;
my $active       = 0;
my $active_batch = 0;
my $batch_count  = 0;

my $next_batch = sub {
  return splice @competitor_ids, 0, $max;
};

my $get_competitors = sub {
  my $sub = __SUB__;

  my @batch = $next_batch->();

  say "Starting batch @{[++$active_batch]} out of $batch_count";

  for my $id (@batch) {
    $active++;
    say "Getting $id";

    $ua->post(
      "http://wsdc-points.us-west-2.elasticbeanstalk.com/lookup/find" => form =>
        {num => $id} => sub ($ua, $tx) {
        $competitors{$id} = $tx->res->json;

        my $delay = $tx->res->code == 200 ? 0.1 : 10;
        say "Waiting $delay seconds" if $delay != 0.1;

        say "ACTIVE: $active";
        $active--;

        Mojo::IOLoop->timer(
          $delay => sub {
            if ($active < $max) {
              $sub->();
            }

            say "Executing ends @{[int(@ends)]}";
            shift(@ends)->();
          }
        );
      }
    );
  }
};

Mojo::IOLoop->delay(
  sub ($delay) {
    for my $letter (@alphabet) {
      say "Getting $letter";
      $ua->post("http://wsdc-points.us-west-2.elasticbeanstalk.com/lookup/find" => form =>
          {q => $letter} => $delay->begin);
    }
  },

  sub ($delay, @txs) {
    for my $tx (@txs) {
      say "Got " . $tx->req->params('q');
      for my $record ($tx->res->json('/names')->@*) {
        push @competitor_ids => $record->{id};
      }
    }

    #@competitor_ids = splice @competitor_ids, 0, 30;

    say "@{[int @competitor_ids]} competitors retrieved";

    my %tmp = map {$_ => 1} @competitor_ids;
    @competitor_ids = keys %tmp;

    say "@{[int @competitor_ids]} competitors after de-duping";

    $batch_count = @competitor_ids / $max;
    push @ends => $delay->begin for @competitor_ids;
    $get_competitors->();
  },

  sub ($delay) {
    spurt +JSON::XS->new->pretty(1)->encode(\%competitors) => 'competitors-pretty.json';
    spurt +JSON::XS->new->encode(\%competitors) => 'competitors.json';
    say "finished";
  }

)->wait;
