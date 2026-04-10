<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:x="http://www.jenitennison.com/xslt/xspec"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                exclude-result-prefixes="#all"
                version="3.0">

   <xsl:template name="x:perform-initial-check-for-lang" as="empty-sequence()">
      <xsl:context-item as="document-node(element(x:description))" use="required" />

      <xsl:for-each select="x:description[empty(@xproc)]">
         <xsl:message terminate="yes">
            <xsl:call-template name="x:prefix-diag-message">
               <xsl:with-param name="message" select="'Missing @xproc.'" />
            </xsl:call-template>
         </xsl:message>
      </xsl:for-each>
      <!-- Setting up the call to the step requires accessing the pipeline being tested,
         so check availability early. -->
      <xsl:variable name="resolved-xproc" as="xs:anyURI?"
         select="x:description/@xproc ! resolve-uri(string(.), base-uri(.))"/>
      <xsl:for-each select="x:description[$resolved-xproc => unparsed-text-available() => not()]">
         <xsl:message terminate="yes">
            <xsl:call-template name="x:prefix-diag-message">
               <xsl:with-param name="message"
                  expand-text="yes">Cannot find pipeline {$resolved-xproc}.</xsl:with-param>
            </xsl:call-template>
         </xsl:message>
      </xsl:for-each>
      <xsl:for-each select="x:description[$resolved-xproc => doc-available() => not()]">
         <xsl:message terminate="yes">
            <xsl:call-template name="x:prefix-diag-message">
               <xsl:with-param name="message"
                  expand-text="yes">Pipeline {$resolved-xproc} is not well-formed.</xsl:with-param>
            </xsl:call-template>
         </xsl:message>
      </xsl:for-each>
   </xsl:template>

</xsl:stylesheet>