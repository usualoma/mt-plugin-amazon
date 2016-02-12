# Copyright (c) 2011 ToI Inc. All rights reserved.
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

package MT::Amazon::S3;

use strict;
use warnings;

use POSIX;
use URI;

sub plugin {
	MT->component('Amazon');
}

my $domain_name_index = 0;
sub new_url {
	my ($scope, $url) = @_;

	my $path = URI->new($url)->path;
	$path =~ s{^/*}{};

	my $config = &plugin->get_config_hash($scope);
	if ($config->{'amazon_s3_distribution_domain_names'}) {
		my $ts = '';
		if ($config->{amazon_s3_cdn_add_hash_value}) {
			require Digest::MD5;
			$ts = '?ts=' . substr(Digest::MD5::md5_hex(rand), 0, 7);
		}

		my @domains = split(
			',', $config->{'amazon_s3_distribution_domain_names'}
		);
		my $res = 'http://' .$domains[$domain_name_index]. '/' . $path . $ts;
		$domain_name_index = ($domain_name_index + 1) % @domains;
		$res;
	}
	else {
		'http://' . $config->{'amazon_s3_bucket'} . '.s3.amazonaws.com/' . $path;
	}
}

sub bucket {
	require Amazon::S3;

	my ($scope) = @_;
	my $config = &plugin->get_config_hash($scope);

	if (
		! $config->{'amazon_s3_access_key'} ||
		! $config->{'amazon_s3_secret_key'}
	) {
		(undef, undef);
	}

	my $s3 = Amazon::S3->new(
		{
			aws_access_key_id     => $config->{'amazon_s3_access_key'},
			aws_secret_access_key => $config->{'amazon_s3_secret_key'},
			retry                 => 1,
		}
	);
	($s3, $s3->bucket($config->{'amazon_s3_bucket'}));
}


sub _hdlr_link {
    my($ctx, $arg, $cond) = @_;
	my $url = $ctx->super_handler($arg, $cond);

    if (my $tmpl_name = $arg->{template}) {
		my $blog = $arg->{blog_id}
			? MT->model('blog')->load( $arg->{blog_id} )
			: $ctx->stash('blog');

        my $blog_id = $blog->id;
        require MT::Template;
        my $tmpl = MT::Template->load({
				identifier => $tmpl_name,
                type => 'index',
				blog_id => $blog_id
			}) || MT::Template->load({
				name => $tmpl_name,
				type => 'index',
				blog_id => $blog_id
			}) || MT::Template->load({
				outfile => $tmpl_name,
				type => 'index',
				blog_id => $blog_id
			}) or return $ctx->error(MT->translate(
				"Can't find template '[_1]'", $tmpl_name ));

		if ($tmpl->amazon_s3_enabled) {
			my $scope = 'blog:' . $blog_id;
			$url =~ s{\Ahttp://[^/]*}{};
			$url =~ s{\A/*}{};
			return &MT::Amazon::S3::new_url($scope, $url);
		}
    }
	return $url;
}

my %mimes = qw(
	js  application/javascript
	css text/css
	xml text/xml
	txt text/plain
);
sub build_file {
	my ($cb, %params) = @_;

	my $tmpl = $params{'Template'};
	my $scope    = 'blog:' . $params{'Blog'}->id;

	return unless
        &plugin->get_config_value('amazon_s3_for_all_template', $scope) ||
        $tmpl->amazon_s3_enabled;

	my ($s3, $bucket) = &MT::Amazon::S3::bucket($scope);
	$s3 or return 1;

	my $url = $params{'FileInfo'}->url;
	$url =~ s{\Ahttp://[^/]*}{};
	$url =~ s{\A/*}{};

	my ($ext) = ($url =~ m/([^\.]+)\z/);
	my $mime = $mimes{$ext} || 'text/html';

	my $lc_time = POSIX::setlocale(&POSIX::LC_TIME);
	POSIX::setlocale(&POSIX::LC_TIME, 'C');

	# store a file in the bucket
	$bucket->add_key($url, Encode::encode('utf-8', ${$params{'content'}}), {
		acl_short    => 'public-read',
		content_type => $mime,
#		expires      => POSIX::strftime("%a, %e %b %H:%M:%S %Y GMT", localtime(time+473040000)),
	}) or die MT->log($s3->err . ": " . $s3->errstr);

	POSIX::setlocale(&POSIX::LC_TIME, $lc_time);

	1;
}

sub template_pre_save {
	my ($cb, $obj, $original) = @_;
	my $app = MT->instance;

	if ($app->param('amazon_s3_enabled_beacon')) {
		$obj->amazon_s3_enabled($app->param('amazon_s3_enabled') ? 1 : 0);
	}

	1;
}

sub param_edit_template_insert_beacon {
    my ($tmpl) = @_;

    my $placement = $tmpl->getElementById('linked_file');

    my $beacon = $tmpl->createTextNode(
        qq(<input type="hidden" name="amazon_s3_enabled_beacon" value="1" />)
    );

    $tmpl->insertAfter($beacon, $placement);
}

sub param_edit_template_insert_enabled {
    my ($tmpl, $hidden) = @_;

    my $placement = $tmpl->getElementById('linked_file');

    my $setting;
    if ($hidden) {
        $setting = $tmpl->createElement('Unless');
        $setting->innerHTML(
            qq(<input type="hidden" name="amazon_s3_enabled" id="amazon_s3_enabled" value="<mt:If name="amazon_s3_enabled">1<mt:Else>0</mt:If>" />)
        );
    }
    else {
        $setting = $tmpl->createElement('app:setting', {
            id => 'amazon_s3_enabled',
            label => &plugin->translate('Deploy to S3.'),
            label_class => 'top-label',
        });
        $setting->innerHTML(
            qq(<input type="checkbox" name="amazon_s3_enabled" id="amazon_s3_enabled" value="1" <mt:If name="amazon_s3_enabled"> checked="checked" </mt:If>" mt:watch-change="1" />)
        );
    }

    $tmpl->insertAfter($setting, $placement);
}

sub param_edit_template {
    my ($cb, $app, $param, $tmpl) = @_;

    &param_edit_template_insert_beacon($tmpl);

    return 1 if $param->{'type'} ne 'index';

    my $blog = MT::Blog->load($param->{'blog_id'})
        or return 1;

    &param_edit_template_insert_enabled(
        $tmpl,
        &plugin->get_config_value(
            'amazon_s3_for_all_template', 'blog:' . $param->{'blog_id'}
        )
    );
}

sub cms_upload_file {
    my ($cb, %param) = @_;

    my $asset = $param{asset};

	$asset->amazon_s3_urls({});
	$asset->save or
		die MT->log($asset->errstr);
}


1;
