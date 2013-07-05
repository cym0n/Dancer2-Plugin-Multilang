package Dancer2::Plugin::Multilang;
use Dancer2 ':syntax';
use Dancer2::Plugin;

register 'language' => sub {
    my $dsl = shift;
    return $dsl->request->params->{'multilang.lang'};
};

on_plugin_import {
    my $dsl = shift;
    $dsl->app->add_hook(
        Dancer2::Core::Hook->new(name => 'before', code => sub {
            my $context = shift;
            my $conf = plugin_setting();
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
                $context->response( $context->request->forward($path, {'multilang.lang' => $lang}, undef));
                $context->response->halt;
            }
        })
     );
     $dsl->app->add_hook(
        Dancer2::Core::Hook->new(name => 'engine.template.after_layout_render', code => sub {
            my $content = shift;
            my $conf = plugin_setting();
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
