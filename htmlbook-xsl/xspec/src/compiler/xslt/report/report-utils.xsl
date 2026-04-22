<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:x="http://www.jenitennison.com/xslt/xspec"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                exclude-result-prefixes="#all"
                version="3.0">

   <xsl:template name="x:wrap-node-constructors-and-undeclare-default-ns" as="element(xsl:element)">
      <xsl:context-item use="absent" />

      <xsl:param name="wrapper-name" as="xs:string" required="yes" />
      <xsl:param name="node-constructors" as="element()" required="yes" />

      <xsl:element name="xsl:element" namespace="{$x:xsl-namespace}">
         <xsl:attribute name="name" select="$wrapper-name" />
         <xsl:attribute name="namespace" />

         <xsl:sequence select="$node-constructors" />
      </xsl:element>
   </xsl:template>

   <xsl:template name="x:call-report-sequence" as="element(xsl:call-template)">
      <!-- Context item is x:scenario or x:expect -->
      <xsl:context-item as="element()" use="required" />

      <xsl:param name="sequence-variable-eqname" as="xs:string" required="yes" />
      <xsl:param name="report-name" as="xs:string" select="'result'" />

      <xsl:element name="xsl:call-template" namespace="{$x:xsl-namespace}">
         <xsl:attribute name="name" select="x:known-UQName('rep:report-sequence')" />

         <xsl:element name="xsl:with-param" namespace="{$x:xsl-namespace}">
            <xsl:attribute name="name" select="'sequence'" />
            <xsl:attribute name="select" select="'$' || $sequence-variable-eqname" />
         </xsl:element>
         <xsl:element name="xsl:with-param" namespace="{$x:xsl-namespace}">
            <xsl:attribute name="name" select="'report-name'" />
            <xsl:attribute name="select" select="x:quote-with-apos($report-name)" />
         </xsl:element>
         <xsl:for-each select="/x:description[@stylesheet]/@result-file-threshold[. ne 'inf']">
            <xsl:element name="xsl:with-param" namespace="{$x:xsl-namespace}">
               <xsl:attribute name="name" select="local-name()" />
               <xsl:attribute name="select" select="." />
            </xsl:element>
         </xsl:for-each>
      </xsl:element>
   </xsl:template>

   <!-- Should not reach for XSLT, only for XProc -->
   <xsl:template name="x:record-port-specific-result"/>
</xsl:stylesheet>