#! /bin/bash

##############################################################################
##
## This script is used to compile a test suite to XSLT, run it, format
## the report and open it in a browser.
##
## It relies on the environment variable $SAXON_HOME to be set to the
## dir Saxon has been installed to (i.e. the containing the Saxon JAR
## file), or on $SAXON_CP to be set to a full classpath containing
## Saxon (and maybe more).  The latter has precedence over the former.
##
## It also uses the environment variable XSPEC_HOME.  It must be set
## to the XSpec install directory.  By default, it uses this script's
## parent dir.
##
## Note: If you use the EXPath Packaging System with Saxon, then you
## already have the script "saxon" shipped with expath-repo.  In that
## case you don't need to do anything, this script will be detected
## and used instead.  You just have to ensure it is visible from here
## (aka "ensure it is in the $PATH").  Even without packaging support,
## this script is a useful way to launch Saxon from the shell.
## 
## TODO: With the Packaging System, there should be no need to set the
## XSPEC_HOME, as we could use absolute public URIs for the public
## components...
##
##############################################################################

##
## utility functions #########################################################
##

usage() {
    if test -n "$1"; then
        echo "$1"
        echo;
    fi
    echo "Usage: xspec [-t|-q|-c|-h] filename [coverage]"
    echo
    echo "  filename   the XSpec document"
    echo "  -t         test an XSLT stylesheet (the default)"
    echo "  -q         test an XQuery module (mutually exclusive with -t)"
    echo "  -c         output test coverage report"
    echo "  -h         display this help message"
    echo "  coverage   deprecated, use -c instead"
}

die() {
    echo
    echo "*** $@" >&2
    exit 1
}

# If there is a script called "saxon" and returning ok (status code 0)
# when called with "--help", we assume this is the EXPath Packaging
# script for Saxon [1].  If it is present, that means the user already
# configured it, so there is no point to duplicate the logic here.
# Just use it.
# [1]http://code.google.com/p/expath-pkg/source/browse/trunk/saxon/pkg-saxon/src/shell/saxon

if which saxon > /dev/null 2>&1; then
    echo Saxon script found, use it.
    echo
    xslt() {
        saxon --add-cp "${XSPEC_HOME}/java/" --xsl "$@"
    }
    xquery() {
        saxon --add-cp "${XSPEC_HOME}/java/" --xq "$@"
    }
else
    echo Saxon script not found, invoking JVM directly instead.
    echo
    xslt() {
        java -cp "$CP" net.sf.saxon.Transform "$@"
    }
    xquery() {
        java -cp "$CP" net.sf.saxon.Query "$@"
    }
fi

##
## some variables ############################################################
##

# the command to use to open the final HTML report
if [ `uname` = "Darwin" ]; then
    OPEN=open
else
    OPEN=see
fi

# the classpath delimiter (aka ':', except ';' on Cygwin)
if uname | grep -i cygwin >/dev/null 2>&1; then
    CP_DELIM=";"
else
    CP_DELIM=":"
fi

# set XSPEC_HOME if it has not been set by the user (set it to the
# parent dir of this script)
if test -z "$XSPEC_HOME"; then
    XSPEC_HOME=`dirname $0`;
    XSPEC_HOME=`dirname $XSPEC_HOME`;
fi
# safety checks
if test \! -d "${XSPEC_HOME}"; then
    echo "ERROR: XSPEC_HOME is not a directory: ${XSPEC_HOME}"
    exit 1;
fi
if test \! -f "${XSPEC_HOME}/src/compiler/generate-common-tests.xsl"; then
    echo "ERROR: XSPEC_HOME seems to be corrupted: ${XSPEC_HOME}"
    exit 1;
fi

# set SAXON_CP (either it has been by the user, or set it from SAXON_HOME)

if test -z "$SAXON_CP"; then
    # Set this variable in your environment or here, if you don't set SAXON_CP
    # SAXON_HOME=/path/to/saxon/dir
    if test -z "$SAXON_HOME"; then
    	echo "SAXON_CP and SAXON_HOME both not set!"
#        die "SAXON_CP and SAXON_HOME both not set!"
    fi
    if test -f "${SAXON_HOME}/saxon9ee.jar"; then
	SAXON_CP="${SAXON_HOME}/saxon9ee.jar";
    elif test -f "${SAXON_HOME}/saxon9pe.jar"; then
	SAXON_CP="${SAXON_HOME}/saxon9pe.jar";
    elif test -f "${SAXON_HOME}/saxon9he.jar"; then
	SAXON_CP="${SAXON_HOME}/saxon9he.jar";
    elif test -f "${SAXON_HOME}/saxon9sa.jar"; then
	SAXON_CP="${SAXON_HOME}/saxon9sa.jar";
    elif test -f "${SAXON_HOME}/saxon9.jar"; then
	SAXON_CP="${SAXON_HOME}/saxon9.jar";
    elif test -f "${SAXON_HOME}/saxon8sa.jar"; then
	SAXON_CP="${SAXON_HOME}/saxon8sa.jar";
    elif test -f "${SAXON_HOME}/saxon8.jar"; then
	SAXON_CP="${SAXON_HOME}/saxon8.jar";
    else
    	echo "Saxon jar cannot be found in SAXON_HOME: $SAXON_HOME"
#        die "Saxon jar cannot be found in SAXON_HOME: $SAXON_HOME"
    fi
fi

CP="${SAXON_CP}${CP_DELIM}${XSPEC_HOME}/java/"

##
## options ###################################################################
##

while echo "$1" | grep -- ^- >/dev/null 2>&1; do
    case "$1" in
        # XSLT
        -t)
            if test -n "$XQUERY"; then
                usage "-t and -q are mutually exclusive"
                exit 1
            fi
            XSLT=1;;
        # XQuery
        -q)
            if test -n "$XSLT"; then
                usage "-t and -q are mutually exclusive"
                exit 1
            fi
            XQUERY=1;;
        # Coverage
        -c)
            COVERAGE=1;;
        # Help!
        -h)
            usage
            exit 0;;
        # Unknown option!
        -*)
            usage "Error: Unknown option: $1"
            exit 1;;
    esac
    shift;
done

# set XSLT if XQuery has not been set (that's the default)
if test -z "$XQUERY"; then
    XSLT=1;
fi

XSPEC=$1
if [ ! -f "$XSPEC" ]; then
    usage "Error: File not found."
    exit 1
fi

if [ -n "$2" ]; then
    if [ "$2" != coverage ]; then
        usage "Error: Extra option: $2"
        exit 1
    fi
    echo "Long-form option 'coverage' deprecated, use '-c' instead."
    COVERAGE=1
    if [ -n "$3" ]; then
        usage "Error: Extra option: $3"
        exit 1
    fi
fi

##
## files and dirs ############################################################
##

TEST_DIR=$(dirname "$XSPEC")/xspec
TARGET_FILE_NAME=$(basename "$XSPEC" | sed 's:\...*$::')

if test -n "$XSLT"; then
    COMPILED=$TEST_DIR/$TARGET_FILE_NAME.xsl
else
    COMPILED=$TEST_DIR/$TARGET_FILE_NAME.xq
fi
COVERAGE_XML=$TEST_DIR/$TARGET_FILE_NAME-coverage.xml
COVERAGE_HTML=$TEST_DIR/$TARGET_FILE_NAME-coverage.html
RESULT=$TEST_DIR/$TARGET_FILE_NAME-result.xml
HTML=$TEST_DIR/$TARGET_FILE_NAME-result.html
COVERAGE_CLASS=com.jenitennison.xslt.tests.XSLTCoverageTraceListener

if [ ! -d "$TEST_DIR" ]; then
    echo "Creating XSpec Directory at $TEST_DIR..."
    mkdir "$TEST_DIR"
    echo
fi 

##
## compile the suite #########################################################
##

if test -n "$XSLT"; then
    COMPILE_SHEET=generate-xspec-tests.xsl
else
    COMPILE_SHEET=generate-query-tests.xsl
fi
echo "Creating Test Stylesheet..."
xslt -o:"$COMPILED" -s:"$XSPEC" \
    -xsl:"$XSPEC_HOME/src/compiler/$COMPILE_SHEET" \
    || die "Error compiling the test suite"
echo

##
## run the suite #############################################################
##

echo "Running Tests..."
if test -n "$XSLT"; then
    # for XSLT
    if test -n "$COVERAGE"; then
        echo "Collecting test coverage data; suppressing progress report..."
        xslt -T:$COVERAGE_CLASS \
            -o:"$RESULT" -s:"$XSPEC" -xsl:"$COMPILED" \
            -it:{http://www.jenitennison.com/xslt/xspec}main 2> "$COVERAGE_XML" \
            || die "Error collecting test coverage data"
    else
        xslt -o:"$RESULT" -s:"$XSPEC" -xsl:"$COMPILED" \
            -it:{http://www.jenitennison.com/xslt/xspec}main \
            || die "Error running the test suite"
    fi
else
    # for XQuery
    if test -n "$COVERAGE"; then
        echo "Collecting test coverage data; suppressing progress report..."
        xquery -T:$COVERAGE_CLASS \
            -o:"$RESULT" -s:"$XSPEC" "$COMPILED" 2> "$COVERAGE_XML" \
            || die "Error collecting test coverage data"
    else
        xquery -o:"$RESULT" -s:"$XSPEC" "$COMPILED" \
            || die "Error running the test suite"
    fi
fi

##
## format the report #########################################################
##

echo
echo "Formatting Report..."
xslt -o:"$HTML" \
    -s:"$RESULT" \
    -xsl:"$XSPEC_HOME/src/reporter/format-xspec-report.xsl" \
    || die "Error formating the report"
if test -n "$COVERAGE"; then
    xslt -l:on \
        -o:"$COVERAGE_HTML" \
        -s:"$COVERAGE_XML" \
        -xsl:"$XSPEC_HOME/src/reporter/coverage-report.xsl" \
        "tests=$XSPEC" \
        "pwd=file:`pwd`/" \
        || die "Error formating the coverage report"
    echo "Report available at $COVERAGE_HTML"
    #$OPEN "$COVERAGE_HTML"
else
    echo "Report available at $HTML"
    #$OPEN "$HTML"
fi

echo "Done."
