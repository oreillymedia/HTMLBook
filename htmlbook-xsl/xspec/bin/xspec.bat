@echo off

rem
rem ##############################################################################
rem ##
rem ## This script is used to compile a test suite to XSLT, run it, format
rem ## the report and open it in a browser.
rem ##
rem ## It relies on the environment variable SAXON_HOME to be set to the
rem ## dir Saxon has been installed to (i.e. the containing the Saxon JAR
rem ## file), or on SAXON_CP to be set to a full classpath containing
rem ## Saxon (and maybe more).  The latter has precedence over the former.
rem ##
rem ## When running tests for Schematron via XQS, the environment variable
rem ## BASEX_JAR must be set to the BaseX.jar file in a BaseX installation.
rem ##
rem ## It also uses the environment variable XSPEC_HOME.  It must be set
rem ## to the XSpec install directory.  By default, it uses this script's
rem ## parent dir.
rem ##
rem ## TODO: Not aware of the EXPath Packaging System
rem ##
rem ##############################################################################
rem
rem Comments (rem)
rem    Comments starting with '#' are derived from xspec.sh (possibly with
rem    some modifications).
rem
rem Environment variables (%FOO%)
rem    Environment variables are tried to be on parity with xspec.sh,
rem    except that those starting with 'WIN_' are only for this batch
rem    file.
rem
rem Labels (:foo)
rem    Labels are tried to be on parity with functions in xspec.sh, except
rem    that those starting with 'win_' are only for this batch file.
rem

rem
rem Skip over "utility functions"
rem
goto :win_main_enter

rem ##
rem ## utility functions #########################################################
rem ##

:usage
    if not "%~1"=="" (
        call :win_echo %1
        echo:
    )
    echo XSpec v%XSPEC_VERSION%
    echo:
    echo Usage: xspec [-t^|-q^|-s^|-p^|-c^|-j^|-catalog file^|-e^|-h] file
    echo:
    echo   file           the XSpec document
    echo   -t             test an XSLT stylesheet (the default)
    echo   -q             test an XQuery module (mutually exclusive with -t, -s, and -p)
    echo   -s             test a Schematron schema (mutually exclusive with -t, -q, and -p)
    echo   -p             test an XProc step (mutually exclusive with -t, -q, and -s)
    echo   -c             output test coverage report (XSLT only)
    echo   -j             output JUnit report
    echo   -catalog file  use XML Catalog file to locate resources
    echo   -e             treat failed tests as error
    echo   -h             display this help message
    goto :EOF

:die
    echo:
    (echo *** %~1) >&2
    rem
    rem Now, to exit the batch file, you must go to :win_main_error_exit from
    rem the main code flow.
    rem
    goto :EOF

:xslt-with-pipeline
    set "PIPELINES=%TEST_DIR%\%TARGET_FILE_NAME%-pipelines.xpl"
    rem # Convey XML Calabash configuration file if XMLCALABASH_CONFIG has been set to a URI
    set XMLCALABASH_CONFIG_ARG=
    if defined XMLCALABASH_CONFIG (
        set XMLCALABASH_CONFIG_ARG=-Dcom.xmlcalabash.configuration="%XMLCALABASH_CONFIG%"
    )

    java -cp "%SAXON_CP%" net.sf.saxon.Transform ^
        -s:"%XSPEC%" ^
        -xsl:"%XSPEC_HOME%\src\compiler\xproc\in-scope-steps\generate-xproc-imports.xsl" ^
        -o:"%PIPELINES%" %CATALOG%
    java ^
        -Dxspec.coverage.ignore="%TEST_DIR%" ^
        -Dxspec.coverage.xml="%COVERAGE_XML%" ^
        -Dxspec.home="%XSPEC_HOME%" ^
        -Dxspec.xspecfile="%XSPEC%" ^
        -Dcom.xmlcalabash.pipelines="%PIPELINES%" ^
        %XMLCALABASH_CONFIG_ARG% ^
        -cp "%CP%" net.sf.saxon.Transform ^
        -init:com.xmlcalabash.api.RegisterSaxonFunctions ^
        %CATALOG% %*
    goto :EOF

:xslt
    java ^
        -Dxspec.coverage.ignore="%TEST_DIR%" ^
        -Dxspec.coverage.xml="%COVERAGE_XML%" ^
        -Dxspec.home="%XSPEC_HOME%" ^
        -Dxspec.xspecfile="%XSPEC%" ^
        -cp "%CP%" net.sf.saxon.Transform %CATALOG% %*
    goto :EOF

:xquery
    java -cp "%CP%" net.sf.saxon.Query %CATALOG% %*
    goto :EOF

:basex
    call "%BASEX_JAR%\..\bin\basex.bat" %*
    goto :EOF

:win_reset_options
    set XSLT=
    set XQUERY=
    set SCHEMATRON=
    set XPROC=
    set COVERAGE=
    set JUNIT=
    set WIN_HELP=
    set WIN_UNKNOWN_OPTION=
    set WIN_EXTRA_OPTION=
    set XSPEC=
    set CATALOG=
    set BASEX_CATALOG=
    set REPORT_THEME=default
    set ERROR_ON_TEST_FAILURE=
    goto :EOF

:win_get_options
    set "WIN_ARGV=%~1"

    if not defined WIN_ARGV (
        goto :EOF
    ) else if "%WIN_ARGV%"=="-t" (
        set XSLT=1
    ) else if "%WIN_ARGV%"=="-q" (
        set XQUERY=1
    ) else if "%WIN_ARGV%"=="-s" (
        set SCHEMATRON=1
    ) else if "%WIN_ARGV%"=="-p" (
        set XPROC=1
    ) else if "%WIN_ARGV%"=="-c" (
        set COVERAGE=1
    ) else if "%WIN_ARGV%"=="-j" (
        set JUNIT=1
    ) else if "%WIN_ARGV%"=="-e" (
        set ERROR_ON_TEST_FAILURE=1
    ) else if "%WIN_ARGV%"=="-h" (
        set WIN_HELP=1
    ) else if "%WIN_ARGV%"=="-catalog" (
        set "XML_CATALOG=%~2"
        shift
    ) else if "%WIN_ARGV:~0,1%"=="-" (
        set "WIN_UNKNOWN_OPTION=%WIN_ARGV%"
    ) else if defined XSPEC (
        set "WIN_EXTRA_OPTION=%WIN_ARGV%"
        goto :EOF
    ) else (
        set "XSPEC=%WIN_ARGV%"
    )

    shift
    goto :win_get_options

:classify_and_process_schematron
    rem # Set QUERYLANGUAGE variable to stylesheet output, which should be xslt or xquery
    FOR /F "delims=" %%V IN ('java -cp "%SAXON_CP%" net.sf.saxon.Transform -s:"%XSPEC%" -xsl:"%XSPEC_HOME%\src\schematron\get-query-binding.xsl" -it %CATALOG%') DO SET "QUERYLANGUAGE=%%V"
    if "%QUERYLANGUAGE%"=="xquery" (
        call :preprocess_schematron-xqs
        set XSLT=
        set XQUERY=1
    ) else (
        call :preprocess_schematron
    )
    goto :EOF

:preprocess_schematron-xqs
    set "SCH_PREPROCESSED_XSPEC=%TEST_DIR%\%TARGET_FILE_NAME%-sch-preprocessed.xspec"
    if not defined XQS_HOME_URI set "XQS_HOME_URI=../../lib/XQS/"
    echo:
    echo Converting Schematron XSpec into XQuery XSpec...
    call :xslt -o:"%SCH_PREPROCESSED_XSPEC%" ^
        -s:"%XSPEC%" ^
        -xsl:"%XSPEC_HOME%\src\schematron\schut-to-xspec.xsl" ^
        stylesheet-uri="irrelevant for XQS but make it nonempty" ^
        sch-impl-name="xqs" ^
        xqs-home="%XQS_HOME_URI%" ^
        || ( call :die "Error converting Schematron XSpec into XQuery XSpec" & goto :win_main_error_exit )
    set "XSPEC=%SCH_PREPROCESSED_XSPEC%"
    echo:
    goto :EOF

:preprocess_schematron
    set "SCH_PREPROCESSED_XSPEC=%TEST_DIR%\%TARGET_FILE_NAME%-sch-preprocessed.xspec"
    set "SCH_PREPROCESSED_XSL=%TEST_DIR%\%TARGET_FILE_NAME%-sch-preprocessed.xsl"
    
    set SCHUT_TO_XSLT_PARAMS=
    if defined SCHEMATRON_XSLT_INCLUDE (
        if "%SCHEMATRON_XSLT_INCLUDE%"=="#none" (
            set SCHUT_TO_XSLT_PARAMS=%SCHUT_TO_XSLT_PARAMS%  STEP1-PREPROCESSOR-URI="%SCHEMATRON_XSLT_INCLUDE%"
        ) else (
            set SCHUT_TO_XSLT_PARAMS=%SCHUT_TO_XSLT_PARAMS% +STEP1-PREPROCESSOR-DOC="%SCHEMATRON_XSLT_INCLUDE%"
        )
    )
    if defined SCHEMATRON_XSLT_EXPAND (
        if "%SCHEMATRON_XSLT_EXPAND%"=="#none" (
            set SCHUT_TO_XSLT_PARAMS=%SCHUT_TO_XSLT_PARAMS%  STEP2-PREPROCESSOR-URI="%SCHEMATRON_XSLT_EXPAND%"
        ) else (
            set SCHUT_TO_XSLT_PARAMS=%SCHUT_TO_XSLT_PARAMS% +STEP2-PREPROCESSOR-DOC="%SCHEMATRON_XSLT_EXPAND%"
        )
    )
    if defined SCHEMATRON_XSLT_COMPILE set SCHUT_TO_XSLT_PARAMS=%SCHUT_TO_XSLT_PARAMS% +STEP3-PREPROCESSOR-DOC="%SCHEMATRON_XSLT_COMPILE%"
    
    echo:
    echo Converting Schematron into XSLT...
    call :xslt ^
        -o:"%SCH_PREPROCESSED_XSL%" ^
        -s:"%XSPEC%" ^
        -xsl:"%XSPEC_HOME%\src\schematron\schut-to-xslt.xsl" ^
        %SCHUT_TO_XSLT_PARAMS% ^
        || ( call :die "Error converting Schematron into XSLT" & goto :win_main_error_exit )
    
    echo:
    echo Converting Schematron XSpec into XSLT XSpec...
    call :xslt -o:"%SCH_PREPROCESSED_XSPEC%" ^
        -s:"%XSPEC%" ^
        -xsl:"%XSPEC_HOME%\src\schematron\schut-to-xspec.xsl" ^
        +stylesheet-doc="%SCH_PREPROCESSED_XSL%" ^
        || ( call :die "Error converting Schematron XSpec into XSLT XSpec" & goto :win_main_error_exit )
    set "XSPEC=%SCH_PREPROCESSED_XSPEC%"
    echo:
    goto :EOF

:win_echo
    rem
    rem Prints a message removing its surrounding quotes (")
    rem
    set "WIN_ECHO_LINE=%~1"
    setlocal enabledelayedexpansion
    echo !WIN_ECHO_LINE!
    goto :EOF

rem
rem Main #########################################################################
rem
:win_main_enter

rem
rem Begin localization of environment changes.
rem Also make sure the command processor extensions are enabled.
rem
verify other 2> NUL
setlocal enableextensions
if errorlevel 1 (
    echo Unable to enable extensions
    exit /b %ERRORLEVEL%
)

rem
rem ##
rem ## some variables ############################################################
rem ##
rem

rem
rem # the command to use to open the final HTML report
rem
rem Include the command line options (and consequently the double quotes)
rem if necessary.
rem
rem set OPEN=start "XSpec Report"

rem
rem # set XSPEC_HOME if it has not been set by the user (set it to the
rem # parent dir of this script)
rem
if not defined XSPEC_HOME set "XSPEC_HOME=%~dp0.."

rem
rem # safety checks
rem
for %%I in ("%XSPEC_HOME%") do echo "%%~aI" | "%SYSTEMROOT%\system32\find" "d" > NUL
if errorlevel 1 (
    call :win_echo "ERROR: XSPEC_HOME is not a directory: %XSPEC_HOME%"
    exit /b 1
)

set XSPEC_VERSION=
set /p XSPEC_VERSION=<"%XSPEC_HOME%\src\common\VERSION"
if not defined XSPEC_VERSION (
    call :win_echo "ERROR: XSPEC_HOME seems to be corrupted: %XSPEC_HOME%"
    exit /b 1
)

rem
rem # set SAXON_CP (either it has been by the user, or set it from SAXON_HOME)
rem

set USE_SAXON_HOME=

if not defined SAXON_CP (
    if not defined SAXON_HOME (
        echo SAXON_CP and SAXON_HOME both not set!
    ) else (
        set USE_SAXON_HOME=1
        for %%I in (
            "%SAXON_HOME%\saxon9?e.jar"
            "%SAXON_HOME%\saxon-?e-??.?*.jar"
        ) do set "SAXON_CP=%%~I"
    )
)

if defined USE_SAXON_HOME (
    if not defined SAXON_CP (
        call :win_echo "Saxon jar cannot be found in SAXON_HOME: %SAXON_HOME%"
    ) else (
        if exist "%SAXON_HOME%\xml-resolver-1.2.jar" (
            set "SAXON_CP=%SAXON_CP%;%SAXON_HOME%\xml-resolver-1.2.jar"
        )
    )
)

set "CP=%SAXON_CP%;%XSPEC_HOME%\java"

rem
rem ##
rem ## options ###################################################################
rem ##
rem

rem
rem Parse command line
rem
call :win_reset_options
call :win_get_options %*

rem
rem # Schematron
rem # XSLT
rem
if defined SCHEMATRON if defined XSLT (
    call :usage "-s and -t are mutually exclusive"
    exit /b 1
)

rem
rem # Schematron
rem # XQuery
rem
if defined SCHEMATRON if defined XQUERY (
    call :usage "-s and -q are mutually exclusive"
    exit /b 1
)

rem
rem # XSLT
rem # XQuery
rem
if defined XSLT if defined XQUERY (
    call :usage "-t and -q are mutually exclusive"
    exit /b 1
)

rem
rem # XProc
rem # XSLT
rem
if defined XPROC if defined XSLT (
    call :usage "-p and -t are mutually exclusive"
    exit /b 1
)

rem
rem # XProc
rem # XQuery
rem
if defined XPROC if defined XQUERY (
    call :usage "-p and -q are mutually exclusive"
    exit /b 1
)

rem
rem # XProc
rem # Schematron
rem
if defined XPROC if defined SCHEMATRON (
    call :usage "-p and -s are mutually exclusive"
    exit /b 1
)

rem
rem # Help!
rem
if defined WIN_HELP (
    call :usage
    exit /b 0
)

rem
rem # Unknown option!
rem
if defined WIN_UNKNOWN_OPTION (
    call :usage "Error: Unknown option: %WIN_UNKNOWN_OPTION%"
    exit /b 1
)

rem
rem # Coverage is only for XSLT
rem
if defined COVERAGE if not ""=="%XQUERY%%SCHEMATRON%%XPROC%" (
    call :usage "Coverage is supported only for XSLT"
    exit /b 1
)

rem
rem # set CATALOG option for Saxon and BaseX if XML_CATALOG has been set
rem
if defined XML_CATALOG (
    set CATALOG=-catalog:"%XML_CATALOG%"
    set BASEX_CATALOG=-OCATALOG="%XML_CATALOG%" -ODTD=true
)

rem
rem # set XSLT if XQuery and XProc have not been set (XSLT is the default)
rem
if not defined XSLT if not defined XQUERY if not defined XPROC set XSLT=1

if not exist "%XSPEC%" (
    call :usage "Error: File not found."
    exit /b 1
)

rem
rem Extra option
rem
if defined WIN_EXTRA_OPTION (
    call :usage "Error: Extra option: %WIN_EXTRA_OPTION%"
    exit /b 1
)

rem

rem
rem ##
rem ## files and dirs ############################################################
rem ##
rem

rem # TEST_DIR (may be relative, may not exist)
if not defined TEST_DIR for %%I in ("%XSPEC%") do set "TEST_DIR=%%~dpIxspec"

for %%I in ("%XSPEC%") do set "TARGET_FILE_NAME=%%~nI"

set "COVERAGE_XML=%TEST_DIR%\%TARGET_FILE_NAME%-coverage.xml"
if not defined COVERAGE_HTML set "COVERAGE_HTML=%TEST_DIR%\%TARGET_FILE_NAME%-coverage.html"
set "RESULT=%TEST_DIR%\%TARGET_FILE_NAME%-result.xml"
set "HTML=%TEST_DIR%\%TARGET_FILE_NAME%-result.html"
set "JUNIT_RESULT=%TEST_DIR%\%TARGET_FILE_NAME%-junit.xml"
set COVERAGE_CLASS=com.jenitennison.xslt.tests.XSLTCoverageTraceListener

if not exist "%TEST_DIR%" (
    call :win_echo "Creating XSpec Directory at %TEST_DIR%..."
    mkdir "%TEST_DIR%"
    echo:
)

if defined SCHEMATRON call :classify_and_process_schematron || goto :win_main_error_exit

rem Forward slash in COMPILED is deliberate; see https://github.com/xspec/xspec/issues/2246#issuecomment-3783402532
set "COMPILED=%TEST_DIR%/%TARGET_FILE_NAME%-compiled"
if defined XQUERY (
    set "COMPILED=%COMPILED%.xq"
) else (
    set "COMPILED=%COMPILED%.xsl"
)

rem
rem ##
rem ## compile the suite #########################################################
rem ##
rem

if defined XSLT (
    set COMPILE_SHEET=compile-xslt-tests.xsl
) else if defined XPROC (
    set COMPILE_SHEET=compile-xproc-tests.xsl
) else (
    set COMPILE_SHEET=compile-xquery-tests.xsl
)
echo Creating Test Runner...
call :xslt -o:"%COMPILED%" -s:"%XSPEC%" ^
    -xsl:"%XSPEC_HOME%\src\compiler\%COMPILE_SHEET%" ^
    || ( call :die "Error compiling the test suite" & goto :win_main_error_exit )
echo:

rem
rem ##
rem ## run the suite #############################################################
rem ##
rem

echo Running Tests...
if defined XSLT (
    rem
    rem # for XSLT or XSLT-based Schematron
    rem
    if defined COVERAGE (
        echo Collecting test coverage data...
        call :xslt %SAXON_CUSTOM_OPTIONS% ^
            -T:%COVERAGE_CLASS% ^
            -o:"%RESULT%" -xsl:"%COMPILED%" ^
            -it:{http://www.jenitennison.com/xslt/xspec}main ^
            || ( call :die "Error collecting test coverage data" & goto :win_main_error_exit )
    ) else (
        call :xslt %SAXON_CUSTOM_OPTIONS% ^
            -o:"%RESULT%" -xsl:"%COMPILED%" ^
            -it:{http://www.jenitennison.com/xslt/xspec}main ^
            || ( call :die "Error running the test suite" & goto :win_main_error_exit )
    )
) else if defined SCHEMATRON (
    rem
    rem # for Schematron via XQS
    rem
    if defined BASEX_JAR (
      call :basex %BASEX_CATALOG% -Q"%COMPILED%" > "%RESULT%" ^
      || ( call :die "Error running the test suite" & goto :win_main_error_exit )
    ) else (
      call :die "Executing test for Schematron with XQS requires BASEX_JAR to be defined" & goto :win_main_error_exit
    )
) else if defined XPROC (
    rem
    rem # for XProc
    rem
    call :xslt-with-pipeline %SAXON_CUSTOM_OPTIONS% ^
            -o:"%RESULT%" -xsl:"%COMPILED%" ^
            -it:{http://www.jenitennison.com/xslt/xspec}main ^
            || ( call :die "Error running the test suite" & goto :win_main_error_exit )
) else (
    rem
    rem # for XQuery
    rem
    call :xquery %SAXON_CUSTOM_OPTIONS% ^
        -o:"%RESULT%" -q:"%COMPILED%" ^
        || ( call :die "Error running the test suite" & goto :win_main_error_exit )
    )
)

rem
rem ##
rem ## format the report #########################################################
rem ##
rem

if not defined HTML_REPORTER_XSL set "HTML_REPORTER_XSL=%XSPEC_HOME%\src\reporter\format-xspec-report.xsl"
if not defined COVERAGE_REPORTER_XSL set "COVERAGE_REPORTER_XSL=%XSPEC_HOME%\src\reporter\coverage-report.xsl"
if defined XSPEC_HTML_REPORT_THEME set "REPORT_THEME=%XSPEC_HTML_REPORT_THEME%"

echo:
echo Formatting Report...
call :xslt -o:"%HTML%" ^
    -s:"%RESULT%" ^
    -xsl:"%HTML_REPORTER_XSL%" ^
    inline-css=true ^
    report-theme=%REPORT_THEME% ^
    || ( call :die "Error formatting the report" & goto :win_main_error_exit )

if defined COVERAGE (
    echo:
    echo Formatting Coverage Report...
    call :xslt -config:"%XSPEC_HOME%\src\reporter\coverage-report-config.xml" ^
        -o:"%COVERAGE_HTML%" ^
        -s:"%COVERAGE_XML%" ^
        -xsl:"%COVERAGE_REPORTER_XSL%" ^
        inline-css=true ^
        report-theme=%REPORT_THEME% ^
        || ( call :die "Error formatting the coverage report" & goto :win_main_error_exit )
    call :win_echo "Report available at %COVERAGE_HTML%"
    rem %OPEN% "%COVERAGE_HTML%"
) else if defined JUNIT (
    echo:
    echo Generating JUnit Report...
    call :xslt -o:"%JUNIT_RESULT%" ^
        -s:"%RESULT%" ^
        -xsl:"%XSPEC_HOME%\src\reporter\junit-report.xsl" ^
        || ( call :die "Error formatting the JUnit report" & goto :win_main_error_exit )
    call :win_echo "Report available at %JUNIT_RESULT%"
) else (
    call :win_echo "Report available at %HTML%"
    rem %OPEN% "%HTML%"
)

rem
rem ##
rem ## error on test failure #####################################################
rem ##
rem

if defined ERROR_ON_TEST_FAILURE (
    call :xslt ^
        -s:"%RESULT%" ^
        -xsl:"%XSPEC_HOME%\src\cli\terminate-on-test-failure.xsl" 2> NUL ^
        || ( call :die "Found a test failure" & goto :win_main_error_exit )
)

echo Done.
exit /b

rem 
rem Error exit ###################################################################
rem 
:win_main_error_exit
if errorlevel 1 (
    exit /b %ERRORLEVEL%
) else (
    exit /b 1
)
