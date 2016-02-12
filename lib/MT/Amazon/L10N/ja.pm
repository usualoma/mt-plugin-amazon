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

package MT::Amazon::L10N::ja;

use strict;
use warnings;

use base 'MT::Amazon::L10N::en_us';
use vars qw( %Lexicon );

%Lexicon = (
	'Function set for Amazon API' => 'Amazon API を使うためのプラグイン',
	'ToI Inc.' => 'ToI企画',
    'Deploy to S3.' => 'S3で公開する',
	'Domain names can be specified by delimiting this value by the comma.' =>
	'CloudFrontで公開する場合のドメイン名を「,」で区切って複数指定できます。',
	'Access Key' => 'Access Key',
	'Secret Key' => 'Secret Key',
	'Bucket' => 'Bucket名',
	'Distribution domain names (Optional)' => 'CDNのドメイン名(任意)',
	'Append Random Value' => 'URLにクエリを付加する',
    "Append random value to the generated URL. Like '?ts=abcdefg'. This feature enables to override existing asset. You may need to do update your CND settings." =>
    "CNDから配信されるアイテムに、「?ts=abcdefg」のようにランダムな値を付加します。<br />同名のファイル名でアイテムを上書きした場合にこの値が更新されるので、<br />上書き時にCNDからも別のファイルをダウンロードさせることができます。<br />(CloudFront の場合は、「Forward Query Strings」を有効にする必要があります)",
	'Suffixes' => 'アップロードする拡張子',
	'Suffixes can be specified by delimiting this value by the comma.' =>
	'拡張子を「,」で区切って複数指定できます。',
	'All files will be uploaded if this value is empty.' =>
	'空欄の場合は全てのファイルがアップロードされます。',
	'For all template' => '全てのテンプレート',
    'Upload all template to S3.' => '全てのテンプレートがアップロードされます。',
);

1;
