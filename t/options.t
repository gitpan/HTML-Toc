#--- options.t ----------------------------------------------------------------
# function: Test HTML::ToC.  In particular test the available options.

use strict;
use Test;

BEGIN { plan tests => 5; }

use HTML::Toc;
use HTML::TocGenerator;
use HTML::TocInsertor;
use HTML::TocUpdator;

my ($filename);

BEGIN {
		# Create test file
	$filename = "file$$.htm";
	die "$filename is already there" if -e $filename;
}


END {
		# Remove test file
	unlink($filename) or warn "Can't unlink $filename: $!";
}


#--- TestAttributeToExcludeToken() --------------------------------------------
# function: Test 'HTML::Toc' option 'attributeToExcludeToken'

sub TestAttributeToExcludeToken {
		# Assemble test file
	open(FILE, ">$filename") || die "Can't create $filename: $!";
	print FILE <<'EOT'; close(FILE);
<body>
   <h1>Chapter 1</h1>
   <h1 class="appendix">Appendix</h1>
</body>
EOT

		# Create objects
	my $toc          = HTML::Toc->new();
	my $tocGenerator = HTML::TocGenerator->new();
	
   $toc->setOptions({
		'attributeToExcludeToken' => 'foo',
		'tokenToToc' => [{
			'tokenBegin' => '<h1 class="foodix">'
		}]
   });
		# Generate ToC
	$tocGenerator->generateFromFile($toc, $filename);
		# Test ToC
	ok($toc->format(), <<EOT);

<!-- Table of Contents generated by Perl - HTML::Toc -->
<ul>
   <li><a href="#h-1">Chapter 1</a></li>
</ul>
<!-- End of generated Table of Contents -->
EOT
}  # TestAttributeToExcludeToken()


#--- TestAttributeToTocToken() ------------------------------------------------
# function: Test 'HTML::Toc' option 'attributeToTocToken'

sub TestAttributeToTocToken {
		# Assemble test file
	open(FILE, ">$filename") || die "Can't create $filename: $!";
	print FILE <<'EOT'; close(FILE);
<body>
   <img src="test.gif" alt="Picture">
</body>
</html>
EOT

		# Create objects
	my $toc          = HTML::Toc->new();
	my $tocGenerator = HTML::TocGenerator->new();
	
   $toc->setOptions({
   	'attributeToTocToken' => 'foo',
      'tokenToToc'   => [{
         'groupId'    => 'image',
         'tokenBegin' => '<img alt="foo">'
      }],
   });
		# Generate ToC
	$tocGenerator->generateFromFile($toc, $filename);
		# Test ToC
	ok($toc->format(), <<EOT);

<!-- Table of Contents generated by Perl - HTML::Toc -->
<ul>
   <li><a href="#image-1">Picture</a></li>
</ul>
<!-- End of generated Table of Contents -->
EOT
}  # TestAttributeToTocToken()


#--- TestNumberingStyleDecimal ------------------------------------------------
# function: Test 'decimal' numbering style.

sub TestNumberingStyleDecimal {
		# Local variables
	my $output;
		# Create objects
	my $toc         = HTML::Toc->new();
	my $tocInsertor = HTML::TocInsertor->new();
	
   $toc->setOptions({
		'doNumberToken' => 1,
      'tokenToToc'   => [{
			'level' => 1,
			'tokenBegin' => '<h1>',
			'numberingStyle' => 'decimal'
      }],
   });
		# Generate ToC
	$tocInsertor->insert($toc, "<h1>Header</h1>", {'output' => \$output});
		# Test ToC
	ok("$output\n", <<EOT);
<h1><a name="h-1"></a>1 &nbsp;Header</h1>
EOT
}  # TestNumberingStyleDecimal()


#--- TestNumberingStyleLowerAlpha ---------------------------------------------
# function: Test 'lower-alpha' numbering style.

sub TestNumberingStyleLowerAlpha {
		# Local variables
	my $output;
		# Create objects
	my $toc         = HTML::Toc->new();
	my $tocInsertor = HTML::TocInsertor->new();
	
   $toc->setOptions({
		'doNumberToken' => 1,
      'tokenToToc'   => [{
			'level' => 1,
			'tokenBegin' => '<h1>',
			'numberingStyle' => 'lower-alpha'
      }],
   });
		# Generate ToC
	$tocInsertor->insert($toc, "<h1>Header</h1>", {'output' => \$output});
		# Test ToC
	ok("$output\n", <<EOT);
<h1><a name="h-a"></a>a &nbsp;Header</h1>
EOT
}  # TestNumberingStyleLowerAlpha()


#--- TestNumberingStyleUpperAlpha ---------------------------------------------
# function: Test 'upper-alpha' numbering style.

sub TestNumberingStyleUpperAlpha {
		# Local variables
	my $output;
		# Create objects
	my $toc         = HTML::Toc->new();
	my $tocInsertor = HTML::TocInsertor->new();
	
   $toc->setOptions({
		'doNumberToken' => 1,
      'tokenToToc'   => [{
			'level' => 1,
			'tokenBegin' => '<h1>',
			'numberingStyle' => 'upper-alpha'
      }],
   });
		# Generate ToC
	$tocInsertor->insert($toc, "<h1>Header</h1>", {'output' => \$output});
		# Test ToC
	ok("$output\n", <<EOT);
<h1><a name="h-A"></a>A &nbsp;Header</h1>
EOT
}  # TestNumberingStyleUpperAlpha()


	# 1. Test 'attributeToTocToken'
TestAttributeToTocToken();
	# 2. Test 'attributeToExcludeToken'
TestAttributeToExcludeToken();
	# 3. Test 'numberingStyleDecimal'
TestNumberingStyleDecimal();
	# 4. Test 'numberingStyleLowerAlpha'
TestNumberingStyleLowerAlpha();
	# 5. Test 'numberingStyleUpperAlpha'
TestNumberingStyleUpperAlpha();
