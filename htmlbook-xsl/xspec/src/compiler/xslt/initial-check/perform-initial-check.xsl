<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:x="http://www.jenitennison.com/xslt/xspec"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                exclude-result-prefixes="#all"
                version="3.0">

   <xsl:template name="x:perform-initial-check-for-lang" as="empty-sequence()">
      <xsl:context-item as="document-node(element(x:description))" use="required" />

      <xsl:for-each select="x:description[empty(@stylesheet)]">
         <xsl:message terminate="yes">
            <xsl:call-template name="x:prefix-diag-message">
               <xsl:with-param name="message" select="'Missing @stylesheet.'" />
            </xsl:call-template>
         </xsl:message>
      </xsl:for-each>
   </xsl:template>

</xsl:stylesheet>