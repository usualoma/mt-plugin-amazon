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

package Amazon;

use strict;
use warnings;

sub init_app {
	require MT::Asset;
	require MT::Asset::Image;
	for my $class ('MT::Asset', 'MT::Asset::Image') {
		$class->install_meta({
			column_defs => {
				'amazon_s3_urls' => 'hash',
			}
		});
	}

	require Amazon::S3::Asset;

	no warnings 'redefine';

	my $original_url = \&MT::Asset::url;
	*MT::Asset::url = sub {
		Amazon::S3::Asset::url($original_url, @_);
	};

	my $original_thumbnail_url = \&MT::Asset::thumbnail_url;
	*MT::Asset::thumbnail_url = sub {
		Amazon::S3::Asset::thumbnail_url($original_thumbnail_url, @_);
	};
}

1;
