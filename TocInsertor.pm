#--- TocInsertor.pm -----------------------------------------------------------
# function: Insert Table of Contents HTML::Toc, generated by 
#           HTML::TocGenerator.
# note:     - The term 'propagate' is used as a shortcut for the process of 
#             both generating and inserting a ToC at the same time.
#           - 'TIP' is an abbreviation of 'Toc Insertion Point'.
#           - `scene' ?
#           - The term `scenario' is used for the output, which is seen as one
#             long story (scenario), split in scenes:
#             +-------------------scenario--------------------+
#             +--scene--+--toc--+--scene--+--scene--+--scene--+



package HTML::TocInsertor;


use strict;
use HTML::TocGenerator;


BEGIN {
    use vars qw(@ISA $VERSION);

    $VERSION = '1.12';

    @ISA = qw(HTML::TocGenerator);
}

    # TocInsertionPoint (TIP) constants
    
use constant TIP_PREPOSITION_REPLACE => 'replace';
use constant TIP_PREPOSITION_BEFORE  => 'before';
use constant TIP_PREPOSITION_AFTER   => 'after';

use constant TIP_TOKEN_ID           => 0;
use constant TIP_PREPOSITION        => 1;
use constant TIP_INCLUDE_ATTRIBUTES => 2;
use constant TIP_EXCLUDE_ATTRIBUTES => 3;
use constant TIP_TOC                => 4;

use constant MODE_DO_NOTHING   => 0;	# 0b00
use constant MODE_DO_INSERT    => 1;	# 0b01
use constant MODE_DO_PROPAGATE => 3;	# 0b11

END {}


#--- HTML::TocInsertor::new() -------------------------------------------------
# function: Constructor.

sub new {
	# Get arguments
    my ($aType) = @_;
    my $self = $aType->SUPER::new;
	# TRUE if insertion point token must be output, FALSE if not
    $self->{_doOutputInsertionPointToken} = 1;
	# True if anchor name is being written to output
    $self->{_writingAnchorName} = 0;
	# True if anchor name-begin is being written to output
    $self->{_writingAnchorNameBegin} = 0;
	# Reset batch variables
    $self->_resetBatchVariables;
	# Bias to not insert ToC
    $self->{hti__Mode} = MODE_DO_NOTHING;

	# TODO: Initialize output

    return $self;
}  # new()


#--- HTML::TocInsertor::_deinitializeOutput() ---------------------------------
# function: Deinitialize output.

sub _deinitializeOutput {
	# Get arguments
    my ($self) = @_;
	# Filehandle is defined?
    if (defined($self->{_outputFileHandle})) {
	# Yes, filehandle is defined;
	    # Restore selected filehandle
	select($self->{_oldFileHandle});
	    # Undefine filehandle, closing it automatically
	undef $self->{_outputFileHandle};
    }
}  # _deinitializeOutput()



#--- HTML::TocInsertor::_initializeOutput() -----------------------------------
# function: Initialize output.

sub _initializeOutput {
	# Get arguments
    my ($self) = @_;
	# Bias to write to outputfile
    my $doOutputToFile = 1;

	# Is output specified?
    if (defined($self->{options}{'output'})) {
	# Yes, output is specified;
	    # Indicate to not output to outputfile
	$doOutputToFile = 0;
	    # Alias output reference
	$self->{_output} = $self->{options}{'output'};
	    # Clear output
	${$self->{_output}} = "";
    }

	# Is output file specified?
    if (defined($self->{options}{'outputFile'})) {
	# Yes, output file is specified;
	    # Indicate to output to outputfile
	$doOutputToFile = 1;
	    # Open file
	open $self->{_outputFileHandle}, ">", $self->{options}{'outputFile'} 
	    or die "Can't create $self->{options}{'outputFile'}: $!";

	    # Backup currently selected filehandle
	$self->{_oldFileHandle} = select;
	    # Set new default filehandle
	select($self->{_outputFileHandle});
    }

	# Alias output-to-file indicator
    $self->{_doOutputToFile} = $doOutputToFile;
}  # _initializeOutput()


#--- HTML::TocInsertor::_deinitializeInsertorBatch() --------------------------
# function: Deinitialize insertor batch.

sub _deinitializeInsertorBatch {
	# Get arguments
    my ($self) = @_;
	# Indicate ToC insertion has finished
    $self->{_isTocInsertionPointPassed} = 0;
	# Write buffered output
    $self->_writeBufferedOutput();
	# Propagate?
    if ($self->{hti__Mode} == MODE_DO_PROPAGATE) {
	# Yes, propagate;
	    # Deinitialize generator batch
	$self->_deinitializeGeneratorBatch();
    }
    else {
	# No, insert only;
	    # Do general batch deinitialization
	$self->_deinitializeBatch();
    }
	# Deinitialize output
    $self->_deinitializeOutput();
	# Indicate end of batch
    $self->{hti__Mode} = MODE_DO_NOTHING;
	# Reset batch variables
    $self->_resetBatchVariables();
}  # _deinitializeInsertorBatch()


#--- HTML::TocInsertor::_initializeInsertorBatch() ----------------------------
# function: Initialize insertor batch.
# args:     - $aTocs: Reference to array of tocs.
#           - $aOptions: optional options

sub _initializeInsertorBatch {
	# Get arguments
    my ($self, $aTocs, $aOptions) = @_;
	# Add invocation options
    $self->setOptions($aOptions);
	# Option 'doGenerateToc' specified?
    if (!defined($self->{options}{'doGenerateToc'})) {
	# No, options 'doGenerateToc' not specified;
	    # Default to 'doGenerateToc'
	$self->{options}{'doGenerateToc'} = 1;
    }
	# Propagate?
    if ($self->{options}{'doGenerateToc'}) {
	# Yes, propagate;
	    # Indicate mode
	$self->{hti__Mode} = MODE_DO_PROPAGATE;
	    # Initialize generator batch
	    # NOTE: This method takes care of calling '_initializeBatch()'
	$self->_initializeGeneratorBatch($aTocs);
    }
    else {
	# No, insert;
	    # Indicate mode
	$self->{hti__Mode} = MODE_DO_INSERT;
	    # Do general batch initialization
	$self->_initializeBatch($aTocs);
    }
	# Initialize output
    $self->_initializeOutput();
	# Parse ToC insertion points
    $self->_parseTocInsertionPoints();
}  # _initializeInsertorBatch()


#--- HTML::TocInsertor::_insert() ---------------------------------------------
# function: Insert ToC in string.
# args:     - $aString: Reference to string to parse.
# note:     Used internally.

sub _insert {
	# Get arguments
    my ($self, $aString) = @_;
	# Propagate?
    if ($self->{options}{'doGenerateToc'}) {
	# Yes, propagate;
	    # Generate & insert ToC
	$self->_generate($aString);
    }
    else {
	# No, just insert ToC
	    # Insert by parsing file
	$self->parse($aString);
	    # Flush remaining buffered text
	$self->eof();
    }
}  # _insert()


#--- HTML::TocInsertor::_insertIntoFile() -------------------------------------
# function: Do insert generated ToCs in file.
# args:     - $aToc: (reference to array of) ToC object(s) to insert.
#           - $aFile: (reference to array of) file(s) to parse for insertion
#                points.
#           - $aOptions: optional insertor options
# note:     Used internally.

sub _insertIntoFile {
	# Get arguments
    my ($self, $aFile) = @_;
	# Local variables;
    my ($file, @files);
	# Dereference array reference or make array of file specification
    @files = (ref($aFile) =~ m/ARRAY/) ? @$aFile : ($aFile);
	# Loop through files
    foreach $file (@files) {
	    # Propagate?
	if ($self->{options}{'doGenerateToc'}) {
	    # Yes, propagate;
		# Generate and insert ToC
	    $self->_generateFromFile($file);
	} else {
	    # No, just insert ToC
		# Insert by parsing file
	    $self->parse_file($file);
	}
    }
}  # _insertIntoFile()


#--- HTML::TocInsertor::_parseTocInsertionPoints() ----------------------------
# function: Parse ToC insertion point specifier.

sub _parseTocInsertionPoints {
	# Get arguments
    my ($self) = @_;
	# Local variables
    my ($tipPreposition, $tipToken, $toc, $tokenTipParser);
	# Create parser for TIP tokens
    $tokenTipParser = HTML::_TokenTipParser->new(
	$self->{_tokensTip}
    );
	# Loop through ToCs
    foreach $toc (@{$self->{_tocs}}) {
	if (length $toc->{options}{'insertionPoint'}) {
		# Split TIP in preposition and token
	    ($tipPreposition, $tipToken) = split(
		'\s+', $toc->{options}{'insertionPoint'}, 2
	    );
		# Known preposition?
	    if (
		($tipPreposition ne TIP_PREPOSITION_REPLACE) &&
		($tipPreposition ne TIP_PREPOSITION_BEFORE) &&
		($tipPreposition ne TIP_PREPOSITION_AFTER)
	    ) {
		# No, unknown preposition;
		    # Use default 'after <body>'
		$tipPreposition = TIP_PREPOSITION_AFTER;
		    # Use entire 'insertionPoint' as token
		$tipToken = $toc->{options}{'insertionPoint'};
	    } # if
	} else {
	    # No, insertion point is empty string;
		# Use default `after <body>'
	    $tipPreposition = TIP_PREPOSITION_AFTER;
	    $tipToken = '<body>';
	} # if
	    # Indicate current ToC to parser
	$tokenTipParser->setToc($toc);
	    # Indicate current preposition to parser
	$tokenTipParser->setPreposition($tipPreposition);
	    # Parse ToC Insertion Point
	$tokenTipParser->parse($tipToken);
	    # Flush remaining buffered text
	$tokenTipParser->eof();
    }
}  # _parseTocInsertionPoints()


#--- HTML::TocInsertor::_processTokenAsInsertionPoint() -----------------------
# function: Check for token being a ToC insertion point (Tip) token and
#           process it accordingly.
# args:     - $aTokenType: type of token: start, end, comment or text.
#           - $aTokenId: token id of currently parsed token
#           - $aTokenAttributes: attributes of currently parsed token
#           - $aOrigText: complete token
# returns:  1 if successful -- token is processed as insertion point, 0
#           if not.

sub _processTokenAsInsertionPoint {
	# Get arguments
    my ($self, $aTokenType, $aTokenId, $aTokenAttributes, $aOrigText) = @_;
	# Local variables
    my ($i, $result, $tipToken, $tipTokenId, $tipTokens);
	# Does token happen to be a ToC token, or is tip-tokentype <> TEXT?
    if ($self->{_doReleaseElement} || $aTokenType != HTML::TocGenerator::TT_TOKENTYPE_TEXT) {
	# No, token isn't a ToC token;
	    # Bias to token not functioning as a ToC insertion point (Tip) token
	$result = 0;
	    # Alias ToC insertion point (Tip) array of right type
	$tipTokens = $self->{_tokensTip}[$aTokenType];
	    # Loop through tipTokens
	$i = 0;
	while ($i < scalar @{$tipTokens}) {
		# Aliases
	    $tipToken		     = $tipTokens->[$i];
	    $tipTokenId		     = $tipToken->[TIP_TOKEN_ID];
		# Id & attributes match?
	    if (
		($aTokenId =~ m/$tipTokenId/) && (
		    HTML::TocGenerator::_doesHashContainHash(
			$aTokenAttributes, $tipToken->[TIP_INCLUDE_ATTRIBUTES], 0
		    ) &&
		    HTML::TocGenerator::_doesHashContainHash(
			$aTokenAttributes, $tipToken->[TIP_EXCLUDE_ATTRIBUTES], 1
		    )
		)
	    ) {
		# Yes, id and attributes match;
		    # Process ToC insertion point
		$self->_processTocInsertionPoint($tipToken, $aTokenType);
		    # Indicate token functions as ToC insertion point
		$result = 1;
		    # Remove Tip token, automatically advancing to next token
		splice(@$tipTokens, $i, 1);
	    } else {
		# No, tag doesn't match ToC insertion point
		    # Advance to next start token
		$i++;
	    } # if
	} # while
	    # Token functions as ToC insertion point?
	if ($result) {
	    # Yes, token functions as ToC insertion point;
		# Process insertion point(s)
	    $self->_processTocInsertionPoints($aOrigText);
	} # if
    } else {
	$result = 0;
    } // if
	# Return value
    return $result;
}  # _processTokenAsInsertionPoint()


#--- HTML::TocInsertor::toc() -------------------------------------------------
# function: Toc processing method.  Add toc reference to scenario.
# args:     - $aScenario: Scenario to add ToC reference to.
#           - $aToc: Reference to ToC to insert.
# note:     The ToC hasn't been build yet; only a reference to the ToC to be
#           build is inserted.

sub toc {
	# Get arguments
    my ($self, $aScenario, $aToc) = @_;
	# Add toc to scenario
    push(@$aScenario, $aToc);
}  # toc()


#--- HTML::TocInsertor::_processTocInsertionPoint() ----------------------------
# function: Process ToC insertion point.
# args:     - $aTipToken: Reference to token array item which matches the ToC 
#                insertion point.
#           - $aTokenType: type of token: start, end, comment or text.

sub _processTocInsertionPoint {
	# Get arguments
    my ($self, $aTipToken, $aTokenType) = @_;
	# Local variables
    my ($tipToc, $tipPreposition); 
    
	# Aliases
    $tipToc         = $aTipToken->[TIP_TOC];
    $tipPreposition = $aTipToken->[TIP_PREPOSITION];

	# If TipToken is of type TEXT, prepend possible preceding string
    if ($aTokenType == HTML::TocGenerator::TT_TOKENTYPE_TEXT && length $`) {
	my $prepend = $`;
	push(@{$self->{_scenarioBeforeToken}}, \$prepend);
    } # if

    SWITCH: {
	    # Replace token with ToC?
	if ($tipPreposition eq TIP_PREPOSITION_REPLACE) {
	    # Yes, replace token;
		# Indicate ToC insertion point has been passed
	    $self->{_isTocInsertionPointPassed} = 1;
		# Add ToC reference to scenario reference by calling 'toc' method
	    $self->toc($self->{_scenarioAfterToken}, $tipToc);
		# Indicate token itself must not be output
	    $self->{_doOutputInsertionPointToken} = 0;
	    last SWITCH;
	} # if
	    # Output ToC before token?
	if ($tipPreposition eq TIP_PREPOSITION_BEFORE) {
	    # Yes, output ToC before token;
		# Indicate ToC insertion point has been passed
	    $self->{_isTocInsertionPointPassed} = 1;
		# Add ToC reference to scenario reference by calling 'toc' method
	    $self->toc($self->{_scenarioBeforeToken}, $tipToc);
		# Add token text
	    if ($aTokenType == HTML::TocGenerator::TT_TOKENTYPE_TEXT) {
		my $text = $&;
		push(@{$self->{_scenarioBeforeToken}}, \$text);
		$self->{_doOutputInsertionPointToken} = 0;
	    } else {
		$self->{_doOutputInsertionPointToken} = ! $self->{_isTocToken};
	    } # if
	    last SWITCH;
	} # if
	    # Output ToC after token?
	if ($tipPreposition eq TIP_PREPOSITION_AFTER) {
	    # Yes, output ToC after token;
		# Indicate ToC insertion point has been passed
	    $self->{_isTocInsertionPointPassed} = 1;
		# Add token text
	    if ($aTokenType == HTML::TocGenerator::TT_TOKENTYPE_TEXT) {
		my $text = $&;
		$self->toc($self->{_scenarioAfterToken}, \$text);
		$self->{_doOutputInsertionPointToken} = 0;
	    } else {
		$self->{_doOutputInsertionPointToken} = ! $self->{_isTocToken};
	    } # if
		# Add ToC reference to scenario reference by calling 'toc' method
	    $self->toc($self->{_scenarioAfterToken}, $tipToc);
	    last SWITCH;
	} # if
    } # SWITCH

	# If TipToken is of type TEXT, append possible following string
    if ($aTokenType == HTML::TocGenerator::TT_TOKENTYPE_TEXT && length $') {
	my $append = $';
	push(@{$self->{_scenarioAfterToken}}, \$append);
    } # if
}  # _processTocInsertionPoint()


#--- HTML::TocInsertor::_processTocInsertionPoints() --------------------------
# function: Process ToC insertion points
# args:     - $aTokenText: Text of token which acts as insertion point for one
#                or multiple ToCs.

sub _processTocInsertionPoints {
	# Get arguments
    my ($self, $aTokenText) = @_;
	# Local variables
    my ($outputPrefix, $outputSuffix);
	# Extend scenario
    push(@{$self->{_scenario}}, @{$self->{_scenarioBeforeToken}});

    if ($outputPrefix = $self->{_outputPrefix}) {
        push(@{$self->{_scenario}}, \$outputPrefix);
	#$self->_writeOrBufferOutput(\$outputPrefix);
        $self->{_outputPrefix} = "";
    }

        # Must insertion point token be output?
    if ($self->{_doOutputInsertionPointToken}) {
        # Yes, output insertion point token;
        push(@{$self->{_scenario}}, \$aTokenText);
	#$self->_writeOrBufferOutput(\$aTokenText);
    }

    if ($outputSuffix = $self->{_outputSuffix}) {
        push(@{$self->{_scenario}}, \$outputSuffix);
	#$self->_writeOrBufferOutput(\$outputSuffix);
        $self->{_outputSuffix} = "";
    }

    push(@{$self->{_scenario}}, @{$self->{_scenarioAfterToken}});
	# Add new act to scenario for output to come
    my $output = "";
    push(@{$self->{_scenario}}, \$output);
	# Write output, processing possible '_outputSuffix'
    #$self->_writeOrBufferOutput("");
	# Reset helper scenario's
    $self->{_scenarioBeforeToken} = [];
    $self->{_scenarioAfterToken}  = [];
	# Reset bias value to output insertion point token
    $self->{_doOutputInsertionPointToken} = 1;
}  # _processTocInsertionPoints()


#--- HTML::Toc::_resetBatchVariables() ----------------------------------------
# function: Reset batch variables.

sub _resetBatchVariables {
    my ($self) = @_;
	# Call ancestor
    $self->SUPER::_resetBatchVariables();
	# Array containing references to scalars.  This array depicts the order
	# in which output must be performed after the first ToC Insertion Point
	# has been passed.
    $self->{_scenario}            = [];
	# Helper scenario
    $self->{_scenarioBeforeToken} = [];
	# Helper scenario
    $self->{_scenarioAfterToken}  = [];
	# Arrays containing start, end, comment, text & declaration tokens which 
	# must trigger the ToC insertion.  Each array element may contain a 
	# reference to an array containing the following elements:
    $self->{_tokensTip} = [
	[], # TT_TOKENTYPE_START
	[], # TT_TOKENTYPE_END
	[], # TT_TOKENTYPE_COMMENT
	[], # TT_TOKENTYPE_TEXT
	[]	# TT_TOKENTYPE_DECLARATION
    ];
	# 1 if ToC insertion point has been passed, 0 if not
    $self->{_isTocInsertionPointPassed} = 0;
	# Tokens after ToC
    $self->{outputBuffer} = "";
	# Trailing text after parsed token
    $self->{_outputSuffix} = "";
	# Preceding text before parsed token
    $self->{_outputPrefix} = "";
}  # _resetBatchVariables()


#--- HTML::TocInsertor::_writeBufferedOutput() --------------------------------
# function: Write buffered output to output device(s).

sub _writeBufferedOutput {
	# Get arguments
    my ($self) = @_;
	# Local variables
    my ($scene);
	# Must ToC be parsed?
    if ($self->{options}{'parseToc'}) {
	# Yes, ToC must be parsed;
	    # Parse ToC
	#$self->parse($self->{toc});
	    # Output tokens after ToC
	#$self->_writeOrBufferOutput($self->{outputBuffer});
    }
    else {
	# No, ToC needn't be parsed;
	    # Output scenario
	foreach $scene (@{$self->{_scenario}}) {
		# Is scene a reference to a scalar?
	    if (ref($scene) eq "SCALAR") {
		# Yes, scene is a reference to a scalar;
		    # Output scene
		$self->_writeOutput($$scene);
	    }
	    else {
		# No, scene must be reference to HTML::Toc;
		    # Output toc
		$self->_writeOutput($scene->format());
	    }
	}
    }
}  # _writeBufferedOutput()


#--- HTML::TocInsertor::_writeOrBufferOutput() --------------------------------
# function: Write processed HTML to output device(s).
# args:     - aOutput: scalar to write
# note:     If '_isTocInsertionPointPassed' text is buffered before being 
#           output because the ToC has to be generated before it can be output.
#           Only after the entire data has been parsed, the ToC and the 
#           following text will be output.

sub _writeOrBufferOutput {
	# Get arguments
    my ($self, $aOutput) = @_;

	# Add possible output prefix and suffix
    $aOutput = $self->{_outputPrefix} . $aOutput . $self->{_outputSuffix};
	# Clear output prefix and suffix
    $self->{_outputPrefix} = "";
    $self->{_outputSuffix} = "";

    if ($self->{_doReleaseElement}) {
	    # Has ToC insertion point been passed?
	if ($self->{_isTocInsertionPointPassed}) {
	    # Yes, ToC insertion point has been passed;
		# Buffer output; add output to last '_scenario' item
	    my $index = scalar(@{$self->{_scenario}}) - 1;
	    ${$self->{_scenario}[$index]} .= $aOutput;
	} else {
	    # No, ToC insertion point hasn't been passed;
		# Write output
	    $self->_writeOutput($aOutput);
	} # if
    } # if
}  # _writeOrBufferOutput()


#--- HTML::TocInsertor::_writeOutput() ----------------------------------------
# function: Write processed HTML to output device(s).
# args:     - aOutput: scalar to write

sub _writeOutput {
	# Get arguments
    my ($self, $aOutput) = @_;
	# Write output to scalar;
    ${$self->{_output}} .= $aOutput if (defined($self->{_output}));
	# Write output to output file
    print $aOutput if ($self->{_doOutputToFile})
}  # _writeOutput()


#--- HTML::TocGenerator::anchorId() -------------------------------------------
# function: Anchor id processing method.
# args:     - $aAnchorId

sub anchorId {
	# Get arguments
    my ($self, $aAnchorId) = @_;
	# Indicate id must be added to start tag
    $self->{_doAddAnchorIdToStartTag} = 1;
    $self->{_anchorId} = $aAnchorId;
}  # anchorId()


#--- HTML::TocInsertor::afterAnchorNameBegin() -------------------------
# Extend ancestor method.
# @see HTML::TocGenerator::afterAnchorNameBegin

sub afterAnchorNameBegin {
	# Get arguments
    my ($self, $aAnchorNameBegin, $aToc) = @_;
	# Store anchor name as output suffix
    #$self->{_outputSuffix} = $aAnchorNameBegin;
    $self->{_holdChildren} = $aAnchorNameBegin . $self->{_holdChildren};
	# Indicate anchor name is being written
    $self->{_writingAnchorNameBegin} = 1;
	# Indicate anchor name end must be output
    $self->{_doOutputAnchorNameEnd} = 1;
} # afterAnchorNameBegin()


#--- HTML::TocInsertor::anchorNameEnd() ---------------------------------------
# function: Process anchor name end, generated by HTML::TocGenerator.
# args:     - $aAnchorNameEnd: Anchor name end tag to output.
#           - $aToc: Reference to ToC to which anchorname belongs.

sub anchorNameEnd {
	# Get arguments
    my ($self, $aAnchorNameEnd) = @_;
	# Store anchor name as output prefix
    $self->{_outputPrefix} .= $aAnchorNameEnd;
	# Is anchor-name-begin being output this parsing round as well?
    if ($self->{_writingAnchorNameBegin}) {
	# Yes, anchor-name-begin is being output as well;
	    # Indicate both anchor name begin and anchor name end are being written
	$self->{_writingAnchorName} = 1;
    } # if
}   # anchorNameEnd()


#--- HTML::TocInsertor::comment() ---------------------------------------------
# function: Process comment.
# args:     - $aComment: comment text with '<!--' and '-->' tags stripped off.

sub comment {
	# Get arguments
    my ($self, $aComment) = @_;
	# Local variables
    my ($tocInsertionPointToken, $doOutput, $origText);
	# Allow ancestor to process the comment tag
    $self->SUPER::comment($aComment);
	# Assemble original comment
    $origText = "<!--$aComment-->";
	# Must ToCs be inserted?
    if ($self->{hti__Mode} & MODE_DO_INSERT) {
	# Yes, ToCs must be inserted;
	    # Processing comment as ToC insertion point is successful?
	if (! $self->_processTokenAsInsertionPoint(
	    HTML::TocGenerator::TT_TOKENTYPE_COMMENT, $aComment, undef, $origText
	)) {
	    # No, comment isn't a ToC insertion point;
		# Output comment normally
	    $self->_writeOrBufferOutput($origText);
	}
    }
}  # comment()


#--- HTML::TocInsertor::declaration() -----------------------------------------
# function: This function is called every time a declaration is encountered
#           by HTML::Parser.

sub declaration {
	# Get arguments
    my ($self, $aDeclaration) = @_;
	# Allow ancestor to process the declaration tag
    $self->SUPER::declaration($aDeclaration);
	# Must ToCs be inserted?
    if ($self->{hti__Mode} & MODE_DO_INSERT) {
	# Yes, ToCs must be inserted;
	    # Processing declaration as ToC insertion point is successful?
	if (! $self->_processTokenAsInsertionPoint(
	    HTML::TocGenerator::TT_TOKENTYPE_DECLARATION, $aDeclaration, undef, 
	    "<!$aDeclaration>"
	)) {
	    # No, declaration isn't a ToC insertion point;
		# Output declaration normally
	    $self->_writeOrBufferOutput("<!$aDeclaration>");
	}
    }
}  # declaration()


#--- HTML::TocInsertor::end() -------------------------------------------------
# function: This function is called every time a closing tag is encountered
#           by HTML::Parser.
# args:     - $aTag: tag name (in lower case).

sub end {
	# Get arguments
    my ($self, $aTag, $aOrigText) = @_;
	# Allow ancestor to process the end tag
    $self->SUPER::end($aTag, $aOrigText);
	# Must ToCs be inserted?
    if ($self->{hti__Mode} & MODE_DO_INSERT) {
	# Yes, ToCs must be inserted;
	    # Processing end tag as ToC insertion point is successful?
	if (! $self->_processTokenAsInsertionPoint(
	    HTML::TocGenerator::TT_TOKENTYPE_END, $aTag, undef, $aOrigText
	)) {
	    # No, end tag isn't a ToC insertion point;
		# Output end tag normally
	    $self->_writeOrBufferOutput($aOrigText);
	}
    }
}  # end()


#--- HTML::TocInsertor::insert() ----------------------------------------------
# function: Insert ToC in string.
# args:     - $aToc: (reference to array of) ToC object to insert
#           - $aString: string to insert ToC in
#           - $aOptions: hash reference with optional insertor options

sub insert {
	# Get arguments
    my ($self, $aToc, $aString, $aOptions) = @_;
	# Initialize TocInsertor batch
    $self->_initializeInsertorBatch($aToc, $aOptions);
	# Do insert Toc
    $self->_insert($aString);
	# Deinitialize TocInsertor batch
    $self->_deinitializeInsertorBatch();
}  # insert()


#--- HTML::TocInsertor::insertIntoFile() --------------------------------------
# function: Insert ToCs in file.
# args:     - $aToc: (reference to array of) ToC object(s) to insert.
#           - $aFile: (reference to array of) file(s) to parse for insertion
#                points.
#           - $aOptions: optional insertor options

sub insertIntoFile {
	# Get arguments
    my ($self, $aToc, $aFile, $aOptions) = @_;
	# Initialize TocInsertor batch
    $self->_initializeInsertorBatch($aToc, $aOptions);
	# Do insert ToCs into file
    $self->_insertIntoFile($aFile);
	# Deinitialize TocInsertor batch
    $self->_deinitializeInsertorBatch();
}  # insertIntoFile()


#--- HTML::TocInsertor::number() ----------------------------------------------
# function: Process heading number generated by HTML::Toc.
# args:     - $aNumber

sub number {
	# Get arguments
    my ($self, $aNumber, $aToc) = @_;
	# Store heading number as output suffix
    #$self->{_outputSuffix} .= $aNumber;
    #$self->_writeOrBufferOutput($aNumber);
    $self->{_holdChildren} = $aNumber . $self->{_holdChildren};
}   # number()


#--- HTML::TocInsertor::_processTocStartingToken() ---------------------------
# Extend ancestor method.

sub _processTocStartingToken {
	# Get arguments
    my ($self, $aTocToken, $aTokenType, $aTokenAttributes, $aTokenOrig) = @_;
    $self->SUPER::_processTocStartingToken($aTocToken, $aTokenType, $aTokenAttributes, $aTokenOrig);
	# Was attribute used as ToC text?
    if (defined($aTocToken->[HTML::TocGenerator::TT_ATTRIBUTES_TOC])) {
        # Yes, attribute was used as ToC text;
            # Output children - containing anchor name only - before toc element
        $self->_writeOrBufferOutput($self->{_holdChildren} . $self->{_holdBeginTokenOrig});
    } else {
	# No, attribute wasn't used as ToC text;
	    # Output children - including anchor name - within toc element
	$self->_writeOrBufferOutput($self->{_holdBeginTokenOrig} . $self->{_holdChildren});
    } # if
} # _processTocStartingToken()


#--- HTML::TocInsertor::propagateFile() ---------------------------------------
# function: Propagate ToC; generate & insert ToC, using file as input.
# args:     - $aToc: (reference to array of) ToC object to insert
#           - $aFile: (reference to array of) file to parse for insertion
#                points.
#           - $aOptions: optional insertor options

sub propagateFile {
	# Get arguments
    my ($self, $aToc, $aFile, $aOptions) = @_;
	# Local variables;
    my ($file, @files);
	# Initialize TocInsertor batch
    $self->_initializeInsertorBatch($aToc, $aOptions);
	# Dereference array reference or make array of file specification
    @files = (ref($aFile) =~ m/ARRAY/) ? @$aFile : ($aFile);
	# Loop through files
    foreach $file (@files) {
	    # Generate and insert ToC
	$self->_generateFromFile($file);
    }
	# Deinitialize TocInsertor batch
    $self->_deinitializeInsertorBatch();
}  # propagateFile()


#--- HTML::TocInsertor::start() -----------------------------------------------
# function: This function is called every time an opening tag is encountered.
# args:     - $aTag: tag name (in lower case).
#           - $aAttr: reference to hash containing all tag attributes (in lower
#                case).
#           - $aAttrSeq: reference to array containing all tag attributes (in 
#                lower case) in the original order
#           - $aTokenOrig: the original token string

sub start {
	# Get arguments
    my ($self, $aTag, $aAttr, $aAttrSeq, $aTokenOrig) = @_;
	# Local variables
    my ($doOutput, $i, $tocToken, $tag, $anchorId);
	# Let ancestor process the start tag
    $self->SUPER::start($aTag, $aAttr, $aAttrSeq, $aTokenOrig);
	# Must ToC be inserted?
    if ($self->{hti__Mode} & MODE_DO_INSERT) {
	# Yes, ToC must be inserted;
	    # Processing start tag as ToC insertion point is successful?
	if (! $self->_processTokenAsInsertionPoint(
	    HTML::TocGenerator::TT_TOKENTYPE_START, $aTag, $aAttr, $aTokenOrig
	)) {
	    # No, start tag isn't a ToC insertion point;
		# Add anchor id?
	    if ($self->{_doAddAnchorIdToStartTag}) {
		# Yes, anchor id must be added;
		    # Reset indicator;
		$self->{_doAddAnchorIdToStartTag} = 0;
		    # Alias anchor id
		$anchorId = $self->{_anchorId};
		    # Attribute 'id' already exists?
		if (defined($aAttr->{id})) {
		    # Yes, attribute 'id' already exists;
			# Show warning
		    print STDERR "WARNING: Overwriting existing id attribute '" .
			$aAttr->{id} . "' of tag $aTokenOrig\n";
		    
			# Add anchor id to start tag
		    $aTokenOrig =~ s/(id)=\S*([\s>])/$1=$anchorId$2/i;
		}
		else {
		    # No, attribute 'id' doesn't exist;
			# Add anchor id to start tag
		    $aTokenOrig =~ s/>/ id=$anchorId>/;
		}
	    } # if
		# Is start tag a ToC token?
	    if (! $self->{_isTocToken}) {
		# No, start tag isn't a ToC token;
		    # Output start tag normally
		$self->_writeOrBufferOutput($aTokenOrig);
	    } # if
	}
    }
}  # start()


#--- HTML::TocInsertor::text() ------------------------------------------------
# function: This function is called every time plain text is encountered.
# args:     - @_: array containing data.

sub text {
	# Get arguments
    my ($self, $aText) = @_;
	# Let ancestor process the text
    $self->SUPER::text($aText);
	# Must ToC be inserted?
    if ($self->{hti__Mode} & MODE_DO_INSERT) {
	# Yes, ToC must be inserted;
	    # Processing text as ToC insertion point is successful?
	if (! $self->_processTokenAsInsertionPoint(
	    HTML::TocGenerator::TT_TOKENTYPE_TEXT, $aText, undef, $aText
	)) {
	    # No, text isn't a ToC insertion point;
		# Output text normally
	    $self->_writeOrBufferOutput($aText);
	}
    }
}  # text()




#=== HTML::_TokenTipParser ====================================================
# function: Parse 'TIP tokens'.  'TIP tokens' mark HTML code which is to be
#           used as the ToC Insertion Point.
# note:     Used internally.

package HTML::_TokenTipParser;


BEGIN {
    use vars qw(@ISA);

    @ISA = qw(HTML::_TokenTocParser);
}


END {}


#--- HTML::_TokenTipParser::new() ---------------------------------------------
# function: Constructor

sub new {
	# Get arguments
    my ($aType, $aTokenArray) = @_;
	# Create instance
    my $self = $aType->SUPER::new;
	# Reference token array
    $self->{tokens} = $aTokenArray;
	# Reference to last added token
    $self->{_lastAddedToken}     = undef;
    $self->{_lastAddedTokenType} = undef;
	# Return instance
    return $self;
}  # new()


#--- HTML::_TokenTipParser::_processAttributes() ------------------------------
# function: Process attributes.
# args:     - $aAttributes: Attributes to parse.

sub _processAttributes {
	# Get arguments
    my ($self, $aAttributes) = @_;
	# Local variables
    my (%includeAttributes, %excludeAttributes);

	# Parse attributes
    $self->_parseAttributes(
	$aAttributes, \%includeAttributes, \%excludeAttributes
    );
	# Include attributes are specified?
    if (keys(%includeAttributes) > 0) {
	# Yes, include attributes are specified;
	    # Store include attributes
	@${$self->{_lastAddedToken}}[
	    HTML::TocInsertor::TIP_INCLUDE_ATTRIBUTES
	] = \%includeAttributes;
    }
	# Exclude attributes are specified?
    if (keys(%excludeAttributes) > 0) {
	# Yes, exclude attributes are specified;
	    # Store exclude attributes
	@${$self->{_lastAddedToken}}[
	    HTML::TocInsertor::TIP_EXCLUDE_ATTRIBUTES
	] = \%excludeAttributes;
    }
}  # _processAttributes()


#--- HTML::_TokenTipParser::_processToken() -----------------------------------
# function: Process token.
# args:     - $aTokenType: Type of token to process.
#           - $aTag: Tag of token.

sub _processToken {
	# Get arguments
    my ($self, $aTokenType, $aTag) = @_;
	# Local variables
    my ($tokenArray, $index);
	# Push element on array of update tokens
    $index = push(@{$self->{tokens}[$aTokenType]}, []) - 1;
	# Alias token array to add element to
    $tokenArray = $self->{tokens}[$aTokenType];
	# Indicate last updated token array element
    $self->{_lastAddedTokenType} = $aTokenType;
    $self->{_lastAddedToken}     = \$$tokenArray[$index];
	# Add fields
    $$tokenArray[$index][HTML::TocInsertor::TIP_TOC]         = $self->{_toc};
    $$tokenArray[$index][HTML::TocInsertor::TIP_TOKEN_ID]   = $aTag;
    $$tokenArray[$index][HTML::TocInsertor::TIP_PREPOSITION] =
	$self->{_preposition};
}  # _processToken()


#--- HTML::_TokenTipParser::comment() -----------------------------------------
# function: Process comment.
# args:     - $aComment: comment text with '<!--' and '-->' tags stripped off.

sub comment {
	# Get arguments
    my ($self, $aComment) = @_;
	# Process token
    $self->_processToken(HTML::TocGenerator::TT_TOKENTYPE_COMMENT, $aComment);
}  # comment()


#--- HTML::_TokenTipParser::declaration() --------------------------------
# function: This function is called every time a markup declaration is
#           encountered by HTML::Parser.
# args:     - $aDeclaration: Markup declaration.

sub declaration {
	# Get arguments
    my ($self, $aDeclaration) = @_;
	# Process token
    $self->_processToken(
	HTML::TocGenerator::TT_TOKENTYPE_DECLARATION, $aDeclaration
    );
}  # declaration()

    
#--- HTML::_TokenTipParser::end() ----------------------------------------
# function: This function is called every time a closing tag is encountered
#           by HTML::Parser.
# args:     - $aTag: tag name (in lower case).

sub end {
	# Get arguments
    my ($self, $aTag, $aOrigText) = @_;
	# Process token
    $self->_processToken(HTML::TocGenerator::TT_TOKENTYPE_END, $aTag);
}  # end()


#--- HTML::_TokenTipParser->setPreposition() ----------------------------------
# function: Set current preposition.

sub setPreposition {
	# Get arguments
    my ($self, $aPreposition) = @_;
	# Set current ToC
    $self->{_preposition} = $aPreposition;
}  # setPreposition()


#--- HTML::_TokenTipParser->setToc() ------------------------------------------
# function: Set current ToC.

sub setToc {
	# Get arguments
    my ($self, $aToc) = @_;
	# Set current ToC
    $self->{_toc} = $aToc;
}  # setToc()


#--- HTML::_TokenTipParser::start() --------------------------------------
# function: This function is called every time an opening tag is encountered.
# args:     - $aTag: tag name (in lower case).
#           - $aAttr: reference to hash containing all tag attributes (in lower
#                case).
#           - $aAttrSeq: reference to array containing all attribute keys (in 
#                lower case) in the original order
#           - $aOrigText: the original HTML text

sub start {
	# Get arguments
    my ($self, $aTag, $aAttr, $aAttrSeq, $aOrigText) = @_;
	# Process token
    $self->_processToken(HTML::TocGenerator::TT_TOKENTYPE_START, $aTag);
	# Process attributes
    $self->_processAttributes($aAttr);
}  # start()


#--- HTML::_TokenTipParser::text() ---------------------------------------
# function: This function is called every time plain text is encountered.
# args:     - @_: array containing data.

sub text {
	# Get arguments
    my ($self, $aText) = @_;
	# Was token already created and is last added token of type 'text'?
    if (
	defined($self->{_lastAddedToken}) && 
	$self->{_lastAddedTokenType} == HTML::TocGenerator::TT_TOKENTYPE_TEXT
    ) {
	# Yes, token is already created;
	    # Add tag to existing token
	@${$self->{_lastAddedToken}}[HTML::TocGenerator::TT_TAG_BEGIN] .= $aText;
    }
    else {
	# No, token isn't created;
	    # Process token
	$self->_processToken(HTML::TocGenerator::TT_TOKENTYPE_TEXT, $aText);
    }
}  # text()


1;
