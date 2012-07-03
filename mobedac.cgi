use strict;
use warnings;
no warnings 'once';

use WebApplication;
use WebMenu;
use WebLayout;
use WebConfig;

use FIG_Config;

use mobedac::WebPage::MetagenomeOverview;

eval {
    &main;
};

if ($@)
{
    my $cgi = new CGI();

    print $cgi->header();
    print $cgi->start_html();
    
    # print out the error
    print '<pre>'.$@.'</pre>';

    print $cgi->end_html();

}

sub main {
    my $range = 2;
    my $random_number = int(rand($range));

    my $base = $FIG_Config::html_base;
    my $cgi_url = $FIG_Config::cgi_url;

    my $layout = WebLayout->new("$base/mobedac.tmpl");
    $layout->add_css("$cgi_url/Html/mobedac.css");
    $layout->add_css("$cgi_url/Html/jquery.fancybox.css");
    $layout->add_javascript("$cgi_url/Html/raphael-min.js");

    # build menu
    my $menu = WebMenu->new();
    $menu->style('horizontal');

    # initialize application
    my $WebApp = WebApplication->new( { id       => 'mobedac',
					menu     => $menu,
					layout   => $layout,
					default  => 'Home',
				      } );
    $WebApp->strict_browser(1);
    $WebApp->page_title_prefix('MoBeDAC - ');
    $WebApp->show_login_user_info(1);
    $WebApp->fancy_login(1);

    my $cgi = new CGI();

    # run application
    $WebApp->run();

}
