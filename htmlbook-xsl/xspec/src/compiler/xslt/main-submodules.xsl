<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.w3.org/1999/XSL/TransformAlias"
                xmlns:x="http://www.jenitennison.com/xslt/xspec"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                exclude-result-prefixes="#all"
                version="3.0">

   <!--
      Sub modules for main.xsl
   -->
   <xsl:include href="main-info-message.xsl" />
   <xsl:include href="catch/try-catch.xsl" />
   <xsl:include href="compile/compile-expect.xsl" />
   <xsl:include href="compile/compile-helpers.xsl" />
   <xsl:include href="compile/compile-scenario.xsl" />
   <xsl:include href="compile/scoped-result.xsl" />
   <xsl:include href="declare-variable/declare-variable.xsl" />
   <xsl:include href="declare-variable/selection-from-doc.xsl" />
   <xsl:include href="external/transform-options.xsl" />
   <xsl:include href="initial-check/perform-initial-check.xsl" />
   <xsl:include href="invoke-compiled/invoke-compiled-current-scenario-or-expect.xsl" />
   <xsl:include href="invoke-compiled/threads.xsl" />
   <xsl:include href="measure-time/timestamp.xsl" />
   <xsl:include href="node-constructor/node-constructor.xsl" />
   <xsl:include href="report/report-utils.xsl" />

</xsl:stylesheet>