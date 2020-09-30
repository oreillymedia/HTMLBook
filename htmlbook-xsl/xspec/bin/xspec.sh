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
        echo
    fi
    echo "Usage: xspec [-t|-q|-s|-c|-j|-catalog file|-h] file"
    echo
    echo "  file           the XSpec document"
    echo "  -t             test an XSLT stylesheet (the default)"
    echo "  -q             test an XQuery module (mutually exclusive with -t and -s)"
    echo "  -s             test a Schematron schema (mutually exclusive with -t and -q)"
    echo "  -c             output test coverage report (XSLT only)"
    echo "  -j             output JUnit report"
    echo "  -catalog file  use XML Catalog file to locate resources"
    echo "  -h             display this help message"
}

die() {
    echo
    echo "*** $*" >&2
    exit 1
}

# If there is a script called "saxon" and returning ok (status code 0)
# when called with "--help", we assume this is the EXPath Packaging
# script for Saxon [1].  If it is present, that means the user already
# configured it, so there is no point to duplicate the logic here.
# Just use it.

if command -v saxon > /dev/null 2>&1 && saxon --help | grep "EXPath Packaging" > /dev/null 2>&1; then
    echo Saxon script found, use it.
    echo
    xslt() {
        saxon \
            --java -Dxspec.coverage.ignore="${TEST_DIR}" \
            --java -Dxspec.coverage.xml="${COVERAGE_XML}" \
            --java -Dxspec.xspecfile="${XSPEC}" \
            --add-cp "${XSPEC_HOME}/java/" ${CATALOG:+"$CATALOG"} --xsl "$@"
    }
    xquery() {
        saxon \
            --java -Dxspec.coverage.ignore="${TEST_DIR}" \
            --java -Dxspec.coverage.xml="${COVERAGE_XML}" \
            --java -Dxspec.xspecfile="${XSPEC}" \
            --add-cp "${XSPEC_HOME}/java/" ${CATALOG:+"$CATALOG"} --xq "$@"
    }
else
    echo Saxon script not found, invoking JVM directly instead.
    echo
    xslt() {
        java \
            -Dxspec.coverage.ignore="${TEST_DIR}" \
            -Dxspec.coverage.xml="${COVERAGE_XML}" \
            -Dxspec.xspecfile="${XSPEC}" \
            -cp "$CP" net.sf.saxon.Transform ${CATALOG:+"$CATALOG"} "$@"
    }
    xquery() {
        java \
            -Dxspec.coverage.ignore="${TEST_DIR}" \
            -Dxspec.coverage.xml="${COVERAGE_XML}" \
            -Dxspec.xspecfile="${XSPEC}" \
            -cp "$CP" net.sf.saxon.Query ${CATALOG:+"$CATALOG"} "$@"
    }
fi

##
## some variables ############################################################
##

# the command to use to open the final HTML report
#if [ $(uname) = "Darwin" ]; then
#    OPEN=open
#else
#    OPEN=see
#fi

# the classpath delimiter (aka ':', except ';' on Cygwin)
if uname | grep -i cygwin > /dev/null 2>&1; then
    CP_DELIM=";"
else
    CP_DELIM=":"
fi

# set XSPEC_HOME if it has not been set by the user (set it to the
# parent dir of this script)
if test -z "$XSPEC_HOME"; then
    XSPEC_HOME=$(dirname "$0")
    XSPEC_HOME=$(dirname "$XSPEC_HOME")
fi
# safety checks
if test \! -d "${XSPEC_HOME}"; then
    echo "ERROR: XSPEC_HOME is not a directory: ${XSPEC_HOME}"
    exit 1
fi
if test \! -f "${XSPEC_HOME}/src/compiler/generate-common-tests.xsl"; then
    echo "ERROR: XSPEC_HOME seems to be corrupted: ${XSPEC_HOME}"
    exit 1
fi

# set SAXON_CP (either it has been by the user, or set it from SAXON_HOME)

unset USE_SAXON_HOME

if test -z "$SAXON_CP"; then
    if test -z "$SAXON_HOME"; then
        echo "SAXON_CP and SAXON_HOME both not set!"
        # die "SAXON_CP and SAXON_HOME both not set!"
    else
        USE_SAXON_HOME=1
        for f in \
            "${SAXON_HOME}"/saxon9?e.jar \
            "${SAXON_HOME}"/saxon-?e-??.?*.jar; do
            [ -f "${f}" ] && SAXON_CP="${f}"
        done
    fi
fi

if [ -n "${USE_SAXON_HOME}" ]; then
    if [ -z "${SAXON_CP}" ]; then
        echo "Saxon jar cannot be found in SAXON_HOME: $SAXON_HOME"
        # die "Saxon jar cannot be found in SAXON_HOME: $SAXON_HOME"
    else
        if test -f "${SAXON_HOME}/xml-resolver-1.2.jar"; then
            SAXON_CP="${SAXON_CP}${CP_DELIM}${SAXON_HOME}/xml-resolver-1.2.jar"
        fi
    fi
fi

CP="${SAXON_CP}${CP_DELIM}${XSPEC_HOME}/java/"

##
## options ###################################################################
##

while echo "$1" | grep -- ^- > /dev/null 2>&1; do
    case "$1" in
        # XSLT
        -t)
            if test -n "$XQUERY"; then
                usage "-t and -q are mutually exclusive"
                exit 1
            fi
            if test -n "$SCHEMATRON"; then
                usage "-s and -t are mutually exclusive"
                exit 1
            fi
            XSLT=1
            ;;
        # XQuery
        -q)
            if test -n "$XSLT"; then
                usage "-t and -q are mutually exclusive"
                exit 1
            fi
            if test -n "$SCHEMATRON"; then
                usage "-s and -q are mutually exclusive"
                exit 1
            fi
            XQUERY=1
            ;;
        # Schematron
        -s)
            if test -n "$XQUERY"; then
                usage "-s and -q are mutually exclusive"
                exit 1
            fi
            if test -n "$XSLT"; then
                usage "-s and -t are mutually exclusive"
                exit 1
            fi
            SCHEMATRON=1
            ;;
        # Coverage
        -c)
            COVERAGE=1
            ;;
        # JUnit report
        -j)
            JUNIT=1
            ;;
        # Catalog
        -catalog)
            shift
            XML_CATALOG="$1"
            ;;
        # Help!
        -h)
            usage
            exit 0
            ;;
        # Unknown option!
        -*)
            usage "Error: Unknown option: $1"
            exit 1
            ;;
    esac
    shift
done

# Coverage is only for XSLT
if [ -n "${COVERAGE}" ] && [ -n "${XQUERY}${SCHEMATRON}" ]; then
    usage "Coverage is supported only for XSLT"
    exit 1
fi

# set CATALOG option for Saxon if XML_CATALOG has been set
if test -n "$XML_CATALOG"; then
    CATALOG="-catalog:$XML_CATALOG"
else
    CATALOG=
fi

# set XSLT if XQuery has not been set (that's the default)
if test -z "$XQUERY"; then
    XSLT=1
fi

XSPEC=$1
if [ ! -f "$XSPEC" ]; then
    usage "Error: File not found."
    exit 1
fi

if [ -n "$2" ]; then
    usage "Error: Extra option: $2"
    exit 1
fi

##
## files and dirs ############################################################
##

# TEST_DIR (may be relative, may not exist)
if [ -z "$TEST_DIR" ]; then
    TEST_DIR=$(dirname "$XSPEC")/xspec
fi

TARGET_FILE_NAME=$(basename "$XSPEC" | sed 's:\.[^.]*$::')

COMPILED="${TEST_DIR}/${TARGET_FILE_NAME}-compiled"
if test -n "$XSLT"; then
    COMPILED="${COMPILED}.xsl"
else
    COMPILED="${COMPILED}.xq"
fi
COVERAGE_XML=$TEST_DIR/$TARGET_FILE_NAME-coverage.xml
if [ -z "${COVERAGE_HTML}" ]; then
    COVERAGE_HTML="${TEST_DIR}/${TARGET_FILE_NAME}-coverage.html"
fi
RESULT=$TEST_DIR/$TARGET_FILE_NAME-result.xml
HTML=$TEST_DIR/$TARGET_FILE_NAME-result.html
JUNIT_RESULT=$TEST_DIR/$TARGET_FILE_NAME-junit.xml
COVERAGE_CLASS=com.jenitennison.xslt.tests.XSLTCoverageTraceListener

if [ ! -d "$TEST_DIR" ]; then
    echo "Creating XSpec Directory at $TEST_DIR..."
    mkdir "$TEST_DIR"
    echo
fi

##
## compile the suite #########################################################
##

if test -n "$SCHEMATRON"; then
    SCH_PREPROCESSED_XSPEC="${TEST_DIR}/${TARGET_FILE_NAME}-sch-preprocessed.xspec"
    SCH_PREPROCESSED_XSL="${TEST_DIR}/${TARGET_FILE_NAME}-sch-preprocessed.xsl"

    SCHUT_TO_XSLT_PARAMS=()
    if [ -n "${SCHEMATRON_XSLT_INCLUDE}" ]; then
        SCHUT_TO_XSLT_PARAMS+=("+STEP1-PREPROCESSOR-DOC=${SCHEMATRON_XSLT_INCLUDE}")
    fi
    if [ -n "${SCHEMATRON_XSLT_EXPAND}" ]; then
        SCHUT_TO_XSLT_PARAMS+=("+STEP2-PREPROCESSOR-DOC=${SCHEMATRON_XSLT_EXPAND}")
    fi
    if [ -n "${SCHEMATRON_XSLT_COMPILE}" ]; then
        SCHUT_TO_XSLT_PARAMS+=("+STEP3-PREPROCESSOR-DOC=${SCHEMATRON_XSLT_COMPILE}")
    fi

    echo
    echo "Converting Schematron into XSLT..."
    xslt \
        -o:"${SCH_PREPROCESSED_XSL}" \
        -s:"${XSPEC}" \
        -xsl:"${XSPEC_HOME}/src/schematron/schut-to-xslt.xsl" \
        "${SCHUT_TO_XSLT_PARAMS[@]}" \
        || die "Error converting Schematron into XSLT"

    echo
    echo "Converting Schematron XSpec into XSLT XSpec..."
    xslt -o:"${SCH_PREPROCESSED_XSPEC}" \
        -s:"${XSPEC}" \
        -xsl:"${XSPEC_HOME}/src/schematron/schut-to-xspec.xsl" \
        +stylesheet-doc="${SCH_PREPROCESSED_XSL}" \
        || die "Error converting Schematron XSpec into XSLT XSpec"
    XSPEC="${SCH_PREPROCESSED_XSPEC}"

    echo
fi

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

# Init otherwise SC2154
saxon_custom_options_array=()

# Split options taking quotes into account (like command arguments)
# https://superuser.com/q/1066455
declare -a "saxon_custom_options_array=(${SAXON_CUSTOM_OPTIONS})"

echo "Running Tests..."
if test -n "$XSLT"; then
    # for XSLT
    if test -n "$COVERAGE"; then
        echo "Collecting test coverage data..."
        xslt "${saxon_custom_options_array[@]}" \
            -T:$COVERAGE_CLASS \
            -o:"$RESULT" -xsl:"$COMPILED" \
            -it:"{http://www.jenitennison.com/xslt/xspec}main" \
            || die "Error collecting test coverage data"
    else
        xslt "${saxon_custom_options_array[@]}" \
            -o:"$RESULT" -xsl:"$COMPILED" \
            -it:"{http://www.jenitennison.com/xslt/xspec}main" \
            || die "Error running the test suite"
    fi
else
    # for XQuery
    if test -n "$COVERAGE"; then
        echo "Collecting test coverage data..."
        xquery "${saxon_custom_options_array[@]}" \
            -T:$COVERAGE_CLASS \
            -o:"$RESULT" -q:"$COMPILED" \
            || die "Error collecting test coverage data"
    else
        xquery "${saxon_custom_options_array[@]}" \
            -o:"$RESULT" -q:"$COMPILED" \
            || die "Error running the test suite"
    fi
fi

##
## format the report #########################################################
##

if [ -z "${HTML_REPORTER_XSL}" ]; then
    HTML_REPORTER_XSL="${XSPEC_HOME}/src/reporter/format-xspec-report.xsl"
fi
if [ -z "${COVERAGE_REPORTER_XSL}" ]; then
    COVERAGE_REPORTER_XSL="$XSPEC_HOME/src/reporter/coverage-report.xsl"
fi

echo
echo "Formatting Report..."
xslt -o:"$HTML" \
    -s:"$RESULT" \
    -xsl:"${HTML_REPORTER_XSL}" \
    inline-css=true \
    || die "Error formatting the report"
if test -n "$COVERAGE"; then
    echo
    echo "Formatting Coverage Report..."
    xslt -config:"${XSPEC_HOME}/src/reporter/coverage-report-config.xml" \
        -o:"$COVERAGE_HTML" \
        -s:"$COVERAGE_XML" \
        -xsl:"${COVERAGE_REPORTER_XSL}" \
        inline-css=true \
        || die "Error formatting the coverage report"
    echo "Report available at $COVERAGE_HTML"
    #$OPEN "$COVERAGE_HTML"
elif test -n "$JUNIT"; then
    echo
    echo "Generating JUnit Report..."
    xslt -o:"$JUNIT_RESULT" \
        -s:"$RESULT" \
        -xsl:"$XSPEC_HOME/src/reporter/junit-report.xsl" \
        || die "Error formatting the JUnit report"
    echo "Report available at $JUNIT_RESULT"
else
    echo "Report available at $HTML"
    #$OPEN "$HTML"
fi

##
## cleanup
##
if test -n "$SCHEMATRON"; then
    rm -f "$SCH_PREPROCESSED_XSPEC"
    rm -f "$TEST_DIR/$TARGET_FILE_NAME-var.txt"
    rm -f "$TEST_DIR/$TARGET_FILE_NAME-step1.sch"
    rm -f "$TEST_DIR/$TARGET_FILE_NAME-step2.sch"
    rm -f "$SCH_PREPROCESSED_XSL"
fi

echo "Done."