#--- format.t -----------------------------------------------------------------
# function: Test ToC formatting.

use strict;
use Test;

BEGIN { plan tests => 6; }

use HTML::Toc;
use HTML::TocGenerator;
use HTML::TocInsertor;

my ($output, $content, $filename);
my $toc          = HTML::Toc->new;
my $tocGenerator = HTML::TocGenerator->new;
my $tocInsertor  = HTML::TocInsertor->new;

$toc->setOptions({
	'doLinkToToken'  => 0,
	'levelIndent'       => 0,
	'insertionPoint'    => 'before <h1>',
	'header'            => '',
	'footer'            => '',
});


BEGIN {
		# Create test file
	$filename = "file$$.htm";
	die "$filename is already there" if -e $filename;
	open(FILE, ">$filename") || die "Can't create $filename: $!";
	print FILE <<'EOT'; close(FILE);
<h1>Header</h1>
EOT
}


END {
		# Remove test file
	unlink($filename) or warn "Can't unlink $filename: $!";
}


#--- 1. templateLevelBegin ----------------------------------------------------

$toc->setOptions({
	'templateLevelBegin' => '"<ul class=toc_$groupId$level>\n"'
});
$tocInsertor->insert($toc, "<h1>Header</h1>", {'output' => \$output});
ok($output, "<ul class=toc_h1>\n<li>Header\n</ul><h1>Header</h1>");
$toc->setOptions({'templateLevelBegin' => undef});


#--- 2. levelToToc -----------------------------------------------------------

$tocGenerator->generate($toc, "<h1>Header1</h1>\n<h2>Header2</h2>");
$toc->setOptions({'levelToToc' => '1'});
ok($toc->format(), "<ul>\n<li>Header1\n</ul>");
$toc->setOptions({'levelToToc' => '.*'});


#--- 3. groupToToc -----------------------------------------------------------

$toc->setOptions({
	'tokenToToc' => [{
		'level' => 1,
		'tokenBegin' => '<h1 class=-foo>'
	}, {
		'groupId' => 'foo',
		'level' => 1,
		'tokenBegin' => '<h1 class=foo>'
	}]
});
$tocGenerator->generate($toc, "<h1>Header1</h1>\n<h1 class=foo>Foo</h1>");
$toc->setOptions({'groupToToc' => 'foo'});
ok($toc->format(), "<ul>\n<li>Foo\n</ul>");
$toc->setOptions({'groupToToc' => '.*'});


#--- 4. header & footer -------------------------------------------------------

$toc->setOptions({
	'tokenToToc' => [{
		'level'      => 1,
		'tokenBegin' => '<h1>'
	}],
	'header' => '<!-- TocHeader -->',
	'footer' => '<!-- TocFooter -->',
});
$tocInsertor->insert($toc, "<h1>Header1</h1>", {'output' => \$output});
ok("$output\n", <<EOT);
<!-- TocHeader --><ul>
<li>Header1
</ul><!-- TocFooter --><h1>Header1</h1>
EOT


	# Test 'doSingleStepLevel' => 1
TestSingleStepLevel1();
	# Test 'doSingleStepLevel' => 0
TestSingleStepLevel0();


#--- 5. TestSingleStepLevel1 --------------------------------------------------

sub TestSingleStepLevel1 {
	my $toc          = new HTML::Toc;
	my $tocGenerator = new HTML::TocGenerator;
	
		# Generate ToC
	$tocGenerator->generate($toc, <<EOT);
<h1>Header 1</h1>
<h3>Header 3</h3>
EOT
		# Compare output
	ok($toc->format(), <<EOT);

<!-- Table of Contents generated by Perl - HTML::Toc -->
<ul>
   <li><a href=#h-1>Header 1</a>
   <ul>
      <ul>
         <li><a href=#h-1.0.1>Header 3</a>
      </ul>
   </ul>
</ul>
<!-- End of generated Table of Contents -->
EOT
}  # TestSingleStepLevel1()


#--- 6. TestSingleStepLevel0 --------------------------------------------------

sub TestSingleStepLevel0 {
	my $toc          = new HTML::Toc;
	my $tocGenerator = new HTML::TocGenerator;
	
		# Set ToC options
	$toc->setOptions({'doSingleStepLevel' => 0});
		# Generate ToC
	$tocGenerator->generate($toc, <<EOT);
<h1>Header 1</h1>
<h3>Header 3</h3>
EOT
	 	# Compare output
	ok($toc->format(), <<EOT);

<!-- Table of Contents generated by Perl - HTML::Toc -->
<ul>
   <li><a href=#h-1>Header 1</a>
   <ul>
      <li><a href=#h-1.0.1>Header 3</a>
   </ul>
</ul>
<!-- End of generated Table of Contents -->
EOT
}  # TestSingleStepLevel0()

