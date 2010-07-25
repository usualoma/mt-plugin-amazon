# Copyright (c) 2010 ToI Inc. All rights reserved.
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

package Amazon::S3::Asset;

use strict;
use warnings;

use POSIX;

sub plugin {
	MT->component('Amazon');
}

sub suffix_is_upload {
	my ($scope, $suffix) = @_;

	my $config = &plugin->get_config_hash($scope);
	if ($config->{'amazon_s3_suffixes'}) {
		my @suffixes = map(
			{ s/^\.//; qr/^$_$/i }
			split(',', $config->{'amazon_s3_suffixes'})
		);
		scalar(grep($suffix =~ $_, @suffixes));
	}
	else {
		1;
	}
}

sub url {
	my $original = shift;
	my $url = $original->(@_);
	my $original_url = $url;
	$url =~ s{\Ahttp://[^/]*}{};
	$url =~ s{\A/*}{};

	my ($asset) = @_;
	my $scope = do {
		if (my $blog = $asset->blog) {
			'blog:' . $blog->id;
		}
		else {
			'system';
		}
	};

	return $original_url unless &suffix_is_upload($scope, $asset->file_ext);

	my $hash = $asset->meta('amazon_s3_urls') || {};
	# 強制的に初期化
	# $hash = {};

	if ($hash->{$url}) {
		$hash->{$url};
	}
	elsif ($url && $asset->file_path) {
		require Amazon::S3;

		my ($s3, $bucket) = &Amazon::S3::bucket($scope);
		$s3 or return $original_url;

		my $lc_time = POSIX::setlocale(&POSIX::LC_TIME);
		POSIX::setlocale(&POSIX::LC_TIME, 'C');

		# store a file in the bucket
		$bucket->add_key_filename($url, $asset->file_path, {
			acl_short => 'public-read',
			content_type => $asset->mime_type,
			expires      => POSIX::strftime("%a, %e %b %H:%M:%S %Y GMT", localtime(time+473040000)),
		}) or die MT->log($s3->err . ": " . $s3->errstr);

		POSIX::setlocale(&POSIX::LC_TIME, $lc_time);

		my $new_url = &Amazon::S3::new_url($scope, $url);

		$hash->{$url} = $new_url;
		$asset->meta('amazon_s3_urls', $hash);

		$asset->save or
			die MT->log($asset->errstr);

		$new_url;
	}
	else {
		$original_url;
	}
}

sub thumbnail_url {
	my $original = shift;
	my ($url, $with, $height) = $original->(@_);

	my $original_url = $url;
	$url =~ s{\Ahttp://[^/]*}{};
	$url =~ s{\A/*}{};

	my ($asset) = @_;
	my $scope = do {
		if (my $blog = $asset->blog) {
			'blog:' . $blog->id;
		}
		else {
			'system';
		}
	};

	return $original_url unless &suffix_is_upload($scope, $asset->file_ext);

	my $hash = $asset->amazon_s3_urls || {};
	# 強制的に初期化
	# $hash = {};

	if ($hash->{$url}) {
		$hash->{$url};
	}
	elsif ($url) {
		shift;

		my ($file, $width, $height) = $asset->thumbnail_file(@_);

		require Amazon::S3;

		my ($s3, $bucket) = &Amazon::S3::bucket($scope);
		$s3 or return $original_url;

		my $lc_time = POSIX::setlocale(&POSIX::LC_TIME);
		POSIX::setlocale(&POSIX::LC_TIME, 'C');

		# store a file in the bucket
		$bucket->add_key_filename($url, $file, {
			acl_short => 'public-read',
			content_type => $asset->mime_type,
			expires      => POSIX::strftime("%a, %e %b %H:%M:%S %Y GMT", localtime(time+473040000)),
		}) or die MT->log($s3->err . ": " . $s3->errstr);

		POSIX::setlocale(&POSIX::LC_TIME, $lc_time);

		my $new_url = &Amazon::S3::new_url($scope, $url);

		$hash->{$url} = $new_url;
		$asset->amazon_s3_urls($hash);

		$asset->save or
			die MT->log($asset->errstr);

		$new_url;
	}
	else {
		$original_url;
	}
}

1;
