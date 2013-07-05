use strict;
use warnings;
use Test::More;

use Test::TCP;
use LWP::UserAgent;


Test::TCP::test_tcp(
    client => sub {
        my $port = shift;

        #Enter with a language-equipped URL
        my $ua = LWP::UserAgent->new;
        $ua->cookie_jar({file => "cookies.txt"});
        $ua->default_header('Accept-Language' => "en");
        my $res = $ua->get("http://127.0.0.1:$port/it/");
        ok($res->is_success);
        is($res->content, 'it');
        $res  = $ua->get("http://127.0.0.1:$port/it/page");
        ok($res->is_success);
        is($res->content, 'page-it');
        $res  = $ua->get("http://127.0.0.1:$port/second");
        ok($res->is_success and $res->previous);
        is($res->content, 'second-it');

        #Enter with no language, but an header
        $ua = LWP::UserAgent->new;
        $ua->cookie_jar({file => "cookies.txt"});
        $ua->default_header('Accept-Language' => "en");
        $res = $ua->get("http://127.0.0.1:$port/page");
        ok($res->is_success and $res->previous);
        is($res->content, 'page-en');
        $res  = $ua->get("http://127.0.0.1:$port/second");
        ok($res->is_success and $res->previous);
        is($res->content, 'second-en');

        #No language and no header, default is used
        $ua = LWP::UserAgent->new;
        $ua->cookie_jar({file => "cookies.txt"});
        $res = $ua->get("http://127.0.0.1:$port/page");
        ok($res->is_success and $res->previous);
        is($res->content, 'page-it');
        $res  = $ua->get("http://127.0.0.1:$port/second");
        ok($res->is_success and $res->previous);
        is($res->content, 'second-it');

        #Language switch
        $ua = LWP::UserAgent->new;
        $ua->cookie_jar({file => "cookies.txt"});
        $ua->default_header('Accept-Language' => "en");
        $res = $ua->get("http://127.0.0.1:$port");
        ok($res->is_success and $res->previous);
        is($res->content, 'en');
        $res = $ua->get("http://127.0.0.1:$port/it/page");
        ok($res->is_success);
        is($res->content, 'page-it');
        $res = $ua->get("http://127.0.0.1:$port/second");
        ok($res->is_success);
        is($res->content, 'second-it');
    },
    server => sub {
        my $port = shift;
        use Dancer2;
        use Dancer2::Plugin::Multilang;

        get '/' => sub {
            return language;
        };      
        get '/page' => sub {
            return 'page-' . language;
        };
        get '/second' => sub {
            return 'second-' . language;
        };

        set(show_errors  => 1,
            startup_info => 0,
            environment  => 'developement',
            port         => $port,
            logger       => 'capture',
            log          => 'debug',
            plugins      => {
                  Multilang => {
                      languages => ['en', 'it', 'de'],
                      default => 'it'
                  }
                }
            );

        Dancer2->runner->server->port($port);
        start;
    },
);
done_testing;
