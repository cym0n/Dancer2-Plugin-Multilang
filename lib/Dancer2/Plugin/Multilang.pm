package Dancer2::Plugin::Multilang;
{
  $Dancer2::Plugin::Multilang::VERSION = '1.0.0';
}
use Dancer2::Plugin;

register 'language' => sub {
    my $dsl = shift;
    return $dsl->request->params->{'multilang.lang'};
};

on_plugin_import {
    my $dsl = shift;
    my $conf = plugin_setting();
    $dsl->app->add_hook(
        Dancer2::Core::Hook->new(name => 'before', code => sub {
            my $context = shift;
            my @managed_languages = @{$conf->{'languages'}};
            my $default_language = $conf->{'default'};
            my $match_string = "^\/(" . join('|', @managed_languages) . ")";
            my $match_regexp = qr/$match_string/;
            my $path = $context->request->path_info();
            my $lang = '';
            if ($path =~ $match_regexp)
            {
                $lang = $1;
            }
            if($lang eq '')
            {
                if($context->request->params->{'multilang.lang'})
                {
                    $dsl->cookie('multilang.lang' => $dsl->param('multilang.lang'));
                }
                else
                {
                    my $accepted_language = $context->request->header('Accept-Language') ?
                                            wanted_language($dsl, $context->request->header('Accept-Language'), @managed_languages) :
                                            '';
                    if($dsl->cookie('multilang.lang'))
                    {
                        $context->response($dsl->redirect("/" . $dsl->cookie('multilang.lang') . $path));
                        $context->response->halt;
                    }
                    elsif($accepted_language ne '')
                    {
                        $context->response($dsl->redirect("/$accepted_language" . $path));
                        $context->response->halt;
                    }
                    else
                    {
                        $context->response($dsl->redirect("/$default_language" . $path));
                        $context->response->halt;
                    }
                }
            }
            else
            {
                $path =~ s/$match_regexp//;
                $context->response( $context->request->forward($context, $path, {'multilang.lang' => $lang}, undef));
                $context->response->halt;

            }
        })
     );
     $dsl->app->add_hook(
        Dancer2::Core::Hook->new(name => 'engine.template.after_layout_render', code => sub {
            my $content = shift;
            my @managed_languages = @{$conf->{'languages'}};
            if(my $selected_lan = $dsl->request->params->{'multilang.lang'})
            {
                for(@managed_languages)
                {
                    my $lan = $_;
                    if($lan ne $selected_lan)
                    {
                        my $meta_for_lan = '<link rel="alternate" hreflang="' . $lan . '" href="' . $dsl->request->base() . $lan . $dsl->request->path() . "\" />\n";
                        $$content =~ s/<\/head>/$meta_for_lan<\/head>/;
                    }
                }                
            }
        })
    );
};

sub wanted_language
{
    my $dsl = shift;
    my $header = shift;
    my @managed_languages = @_;
    my @lan_strings = split(',', $header);
    for(@lan_strings)
    {
        my $str = $_;
        $str =~ m/^(..?)(\-.+)?$/; #Only primary tag is considered
        my $lan = $1;
        if (grep {$_ eq $lan} @managed_languages) {
            return $lan;
        }
    }
    return '';
};

register_plugin for_versions => [ 2 ];

1;

=encoding utf8

=head1 NAME

Dancer2::Plugin::Multilang - Dancer2 Plugin to create multilanguage sites


=head1 DESCRIPTION

A plugin for Dancer2 to create multilanguage sites. In your app you can configure any route you want, as /myroute/to/page.

Plugin will make the app answer to /en/myroute/to/page or /it/myroute/to/page giving the language path to the route manager as a Dancer keyword.
It will also redirect navigation using information from the headers transmitted from the browser. Language change during navigation will be managed via cookie.

Multilanguage SEO headers will be generated to give advice to the search engines about the language of the pages.

=head1 SYNOPSIS

    # In your Dancer2 app,
    use Dancer2::Plugin::Multilang

    #In your config.yml
    plugins: 
      Multilang: 
        languages: ['it', 'en'] 
        default: 'it'

    where languages is the array of all the languages managed and default is the response language if no information about language can be retrieved.

    #In the routes
    get '/route/to/page' => sub {
        if( language == 'en' )
        {
            /* english navigation */
        }
        elsif( language == 'it' )
        {
            /* italian navigation */
        }
        elsif...

=head1 USAGE

No language information has to be managed in route definition. Language path will be added transparently to your routes.

language keyword can be used to retrieve language information inside the route manager.

=head1 OPTIONS

The options you can configure are:

=over 4

=item C<languages> (required)

The array of the languages that will be managed. 

All the languages are two characters codes as in the primary tag defined by http://www.w3.org/Protocols/rfc2616/rfc2616-sec3.html#sec3.10

=item C<default> (required)

The default language that will be used when plugin can't guess desired one (or when desired one is not managed)

=cut

