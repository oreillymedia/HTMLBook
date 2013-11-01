@echo off

SET CP=C:\Program Files (x86)\Oxygen XML Editor\lib\saxon9sa.jar

SET XSPEC=%1

REM ==========================================
REM Check if a parameter was passed
REM ==========================================
IF %XSPEC%x == x GOTO notfound

REM ==========================================
REM Check if xspec document exists
REM ==========================================
IF NOT EXIST %XSPEC% GOTO notfound
GOTO endif1

:notfound
echo File not found.
echo Usage:
echo   xspec filename [coverage]
echo     filename should specify an XSpec document
echo     if coverage is specified, outputs test coverage report
GOTO end
:endif1


SET COVERAGE=%2

SET TEST_DIR=%~dp1xspec
SET TARGET_FILE_NAME=%~n1

SET TEST_STYLESHEET="%TEST_DIR%\%TARGET_FILE_NAME%.xsl"
SET COVERAGE_XML="%TEST_DIR%\%TARGET_FILE_NAME%-coverage.xml"
SET COVERAGE_HTML="%TEST_DIR%\%TARGET_FILE_NAME%-coverage.html"
SET RESULT="%TEST_DIR%\%TARGET_FILE_NAME%-result.xml"
SET HTML="%TEST_DIR%\%TARGET_FILE_NAME%-result.html"

REM ================================================
REM Create xspec subdirectory for running the tests
REM ================================================
IF NOT EXIST "%TEST_DIR%" GOTO notestdir
GOTO endif2
:notestdir
echo Creating XSpec Directory at "%TEST_DIR%" ...
mkdir "%TEST_DIR%"
echo.
:endif2

echo Creating Test Stylesheet...
echo %TEST_STYLESHEET%
echo %XSPEC%
java -cp "%CP%" net.sf.saxon.Transform -o:%TEST_STYLESHEET% -s:%XSPEC% -xsl:"%~dp0\..\src\compiler\generate-xspec-tests.xsl"
echo. 

echo Running Tests...

REM =======================================
REM Check if coverage parameter was passed
REM =======================================
IF %COVERAGE%x == coveragex GOTO coverage
GOTO endif3
:coverage
echo Collecting test coverage data; suppressing progress report...
 java -cp "%CP%" net.sf.saxon.Transform -T:com.jenitennison.xslt.tests.XSLTCoverageTraceListener	\
     -o:%RESULT% -s:%XSPEC% -xsl:%TEST_STYLESHEET% -it:{http://www.jenitennison.com/xslt/xspec}main 2> %COVERAGE_XML%
 
:endif3

REM =======================================
REM Run the tests
REM =======================================
java -cp "%CP%" net.sf.saxon.Transform -o:%RESULT% -s:%XSPEC% -xsl:%TEST_STYLESHEET% -it:{http://www.jenitennison.com/xslt/xspec}main

echo.  
echo Formatting Report...
java -cp "%CP%" net.sf.saxon.Transform -o:%HTML% -s:%RESULT% -xsl:"%~dp0\..\src\reporter\format-xspec-report.xsl"

REM =======================================
REM Check if coverage parameter was passed
REM =======================================
IF %COVERAGE%x == coveragex GOTO coverage2
GOTO endif4
:coverage2 
 java -cp "%CP%" net.sf.saxon.Transform -l:on -o:%COVERAGE_HTML% -s:%COVERAGE_XML% -xsl:"%~dp0\..\src\reporter\coverage-report.xsl" "tests=%XSPEC%"
 %COVERAGE_HTML% 
:endif4

REM =============
REM Output report
REM =============
%HTML%

echo Done.
:end
