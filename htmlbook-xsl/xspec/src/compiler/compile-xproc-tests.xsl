<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:pkg="http://expath.org/ns/pkg"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                exclude-result-prefixes="#all"
                version="3.0">

   <pkg:import-uri>http://www.jenitennison.com/xslt/xspec/compile-xproc-tests.xsl</pkg:import-uri>

   <xsl:variable name="test-type" as="xs:string" select="'xproc'" static="yes"/>

   <!--
      Library modules
   -->
   <xsl:include href="../common/common-utils.xsl" />
   <xsl:include href="../common/namespace-vars.xsl" />
   <xsl:include href="../common/trim.xsl" />
   <xsl:include href="../common/uqname-utils.xsl" />
   <xsl:include href="../common/uri-utils.xsl" />
   <xsl:include href="../common/user-content-utils.xsl" />
   <xsl:include href="../common/version-utils.xsl" />
   <xsl:include href="../common/yes-no-utils.xsl" />

   <!--
      Main modules
   -->
   <xsl:include href="base/main.xsl" />
   <xsl:include href="xproc/main.xsl" />
   <xsl:include href="xproc/main-submodules.xsl" />

</xsl:stylesheet>
