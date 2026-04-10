<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:x="http://www.jenitennison.com/xslt/xspec"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                exclude-result-prefixes="#all"
                version="3.0">

   <xsl:template name="x:compile-helpers" as="text()*">
      <xsl:context-item as="element(x:description)" use="required" />

      <xsl:for-each select="x:helper[@query]">
         <xsl:text expand-text="yes">import module "{@query}"</xsl:text>
         <xsl:if test="exists(@query-at)">
            <xsl:text expand-text="yes">&#x0A;at "{@query-at}"</xsl:text>
         </xsl:if>
         <xsl:text>;&#x0A;</xsl:text>
      </xsl:for-each>
   </xsl:template>

</xsl:stylesheet>