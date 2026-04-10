<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.w3.org/1999/XSL/TransformAlias"
    xmlns:x="http://www.jenitennison.com/xslt/xspec" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" exclude-result-prefixes="#all" version="3.0">

    <!--
        Sub modules specific to compiling test suites for XProc
     -->
    <xsl:include href="main-info-message.xsl"/>
    <xsl:include href="catch/try-catch.xsl"/>
    <xsl:include href="compile/compile-scenario.xsl"/>
    <xsl:include href="compile/scoped-result.xsl"/>
    <xsl:include href="compile/get-step-declaration.xsl"/>
    <xsl:include href="declare-variable/selection-from-doc.xsl"/>
    <xsl:include href="in-scope-steps/generate-test-case-step.xsl"/>
    <xsl:include href="initial-check/perform-initial-check.xsl"/>
    <xsl:include href="report/report-utils.xsl"/>

    <!--
        Sub modules shared with compiling test suites for XSLT
     -->
    <xsl:import href="../xslt/main-info-message.xsl"/>
    <xsl:include href="../xslt/compile/compile-expect.xsl"/>
    <xsl:include href="../xslt/compile/compile-helpers.xsl"/>
    <xsl:include href="../xslt/declare-variable/declare-variable.xsl"/>
    <!--<xsl:include href="../xslt/external/transform-options.xsl" />-->
    <xsl:include href="../xslt/invoke-compiled/invoke-compiled-current-scenario-or-expect.xsl"/>
    <xsl:include href="../xslt/invoke-compiled/threads.xsl"/>
    <xsl:include href="../xslt/measure-time/timestamp.xsl"/>
    <xsl:include href="../xslt/node-constructor/node-constructor.xsl"/>
    <xsl:import href="../xslt/report/report-utils.xsl"/>

</xsl:stylesheet>
