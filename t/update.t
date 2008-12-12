#--- update.t -----------------------------------------------------------------
# function: Test ToC updating.

use strict;
use Test;

BEGIN { plan tests => 6; }

use HTML::Toc;
use HTML::TocUpdator;

my ($output, $output2, $content, $filename);
my $toc         = HTML::Toc->new;
my $tocUpdator  = HTML::TocUpdator->new;

$toc->setOptions({
	'doLinkToToken'  => 1,
	'doNumberToken'  => 1,
	'levelIndent'    => 0,
	'insertionPoint' => 'before <h1>',
	'header'         => '',
	'footer'         => '',
});


BEGIN {
		# Create test file
	$filename = "file$$.htm";
	die "$filename is already there" if -e $filename;
	open my $file, ">", $filename or die "Can't create $filename: $!";
	print $file <<'EOT'; close $file;
<h1>Header</h1>
EOT
}


END {
		# Remove test file
	unlink($filename) or warn "Can't unlink $filename: $!";
}


#--- 1. update ----------------------------------------------------------------

$tocUpdator->update($toc, "<h1>Header</h1>", {'output' => \$output});
ok("$output\n", <<HTML);
<!-- #BeginToc --><ul>
<li><a href="#h-1">Header</a></li>
</ul><!-- #EndToc --><h1><!-- #BeginTocAnchorNameBegin --><a name="h-1"></a><!-- #EndTocAnchorNameBegin --><!-- #BeginTocNumber -->1 &nbsp;<!-- #EndTocNumber -->Header</h1>
HTML

#--- 2. updateFile ------------------------------------------------------------

$tocUpdator->updateFile($toc, $filename, {'output' => \$output});
	open(FILE, ">a.out1") || die "Can't create a.out1: $!";
	print FILE $output; close(FILE);
$output2 = <<HTML;
<!-- #BeginToc --><ul>
<li><a href="#h-1">Header</a></li>
</ul><!-- #EndToc --><h1><!-- #BeginTocAnchorNameBegin --><a name="h-1"></a><!-- #EndTocAnchorNameBegin --><!-- #BeginTocNumber -->1 &nbsp;<!-- #EndTocNumber -->Header</h1>
HTML
	open(FILE, ">a.out2") || die "Can't create a.out2: $!";
	print FILE $output2; close(FILE);
ok($output, $output2);


#--- 3. insert ----------------------------------------------------------------

$tocUpdator->insert($toc, "<h1>Header</h1>", {'output' => \$output});
ok("$output\n", <<HTML);
<!-- #BeginToc --><ul>
<li><a href="#h-1">Header</a></li>
</ul><!-- #EndToc --><h1><!-- #BeginTocAnchorNameBegin --><a name="h-1"></a><!-- #EndTocAnchorNameBegin --><!-- #BeginTocNumber -->1 &nbsp;<!-- #EndTocNumber -->Header</h1>
HTML

#--- 4. insertIntoFile --------------------------------------------------------

$tocUpdator->insertIntoFile($toc, $filename, {'output' => \$output});
ok($output, <<HTML);
<!-- #BeginToc --><ul>
<li><a href="#h-1">Header</a></li>
</ul><!-- #EndToc --><h1><!-- #BeginTocAnchorNameBegin --><a name="h-1"></a><!-- #EndTocAnchorNameBegin --><!-- #BeginTocNumber -->1 &nbsp;<!-- #EndTocNumber -->Header</h1>
HTML


#--- 5. update twice ----------------------------------------------------------

$tocUpdator->update($toc, "<h1>Header</h1>", {'output' => \$output});
$tocUpdator->update($toc, $output, {'output' => \$output2});
ok("$output\n", <<'EOT');
<!-- #BeginToc --><ul>
<li><a href="#h-1">Header</a></li>
</ul><!-- #EndToc --><h1><!-- #BeginTocAnchorNameBegin --><a name="h-1"></a><!-- #EndTocAnchorNameBegin --><!-- #BeginTocNumber -->1 &nbsp;<!-- #EndTocNumber -->Header</h1>
EOT


#--- 6. tokens update begin & end ---------------------------------------------

$toc->setOptions({
	'templateAnchorNameBegin'           => '"<a name>"',
	'templateAnchorNameEnd'             => '"</a>"',
	'tokenUpdateBeginOfAnchorNameBegin' => '<tocAnchorNameBegin>',
	'tokenUpdateEndOfAnchorNameBegin'   => '</tocAnchorNameBegin>',
	'tokenUpdateBeginOfAnchorNameEnd'   => '<tocAnchorNameEnd>',
	'tokenUpdateEndOfAnchorNameEnd'     => '</tocAnchorNameEnd>',
	'tokenUpdateBeginNumber'            => '<tocNumber>',
	'tokenUpdateEndNumber'              => '</tocNumber>',
	'tokenUpdateBeginToc'               => '<toc>',
	'tokenUpdateEndToc',                => '</toc>'
});
$tocUpdator->update($toc, "<h1>Header</h1>", {'output' => \$output});
ok("$output\n", <<HTML);
<toc><ul>
<li><a href="#h-1">Header</a></li>
</ul></toc><h1><tocAnchorNameBegin><a name></tocAnchorNameBegin><tocNumber>1 &nbsp;</tocNumber>Header<tocAnchorNameEnd></a></tocAnchorNameEnd></h1>
HTML
