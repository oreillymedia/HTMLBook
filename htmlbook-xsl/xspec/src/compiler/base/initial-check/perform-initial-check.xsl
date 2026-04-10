<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:x="http://www.jenitennison.com/xslt/xspec"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                exclude-result-prefixes="#all"
                version="3.0">

   <xsl:template name="x:perform-initial-check" as="empty-sequence()">
      <xsl:context-item as="document-node()" use="required" />

      <xsl:call-template name="x:report-xspec-version"/>

      <xsl:variable name="deprecation-warning" as="xs:string?">
         <xsl:choose>
            <xsl:when test="$x:saxon-version lt x:pack-version((11, 0))">
               <xsl:text>Saxon version 10 or earlier is not supported.</xsl:text>
            </xsl:when>
           <xsl:when test="$x:saxon-version lt x:pack-version((12, 4))">
             <xsl:text>Saxon version 12.3 or earlier is not recommended. Consider migrating to Saxon 12.4 or later.</xsl:text>
           </xsl:when>
         </xsl:choose>
      </xsl:variable>
      <xsl:message>
         <xsl:choose>
            <xsl:when test="$deprecation-warning">
               <xsl:call-template name="x:prefix-diag-message">
                  <xsl:with-param name="level" select="'WARNING'" />
                  <xsl:with-param name="message" select="$deprecation-warning" />
               </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
               <!-- Always write a single non-empty line to help Bats tests to predict line numbers. -->
               <xsl:text>Checking for deprecated Saxon versions: Passed</xsl:text>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:message>

      <xsl:variable name="description-name" as="xs:QName" select="xs:QName('x:description')" />
      <xsl:if test="not(node-name(element()) eq $description-name)">
         <xsl:message terminate="yes">
            <xsl:call-template name="x:prefix-diag-message">
               <xsl:with-param name="message">
                  <xsl:text expand-text="yes">Source document is not XSpec. /{$description-name} is missing. Supplied source has /{element() => name()} instead.</xsl:text>
               </xsl:with-param>
            </xsl:call-template>
         </xsl:message>
      </xsl:if>

      <xsl:call-template name="x:perform-initial-check-for-lang" />
   </xsl:template>

   <xsl:template name="x:report-xspec-version" as="empty-sequence()">
      <xsl:message>XSpec v<xsl:value-of select="$x:xspec-version"/></xsl:message>
   </xsl:template>
</xsl:stylesheet>