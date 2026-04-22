<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.w3.org/1999/XSL/TransformAlias"
   xmlns:x="http://www.jenitennison.com/xslt/xspec" xmlns:xs="http://www.w3.org/2001/XMLSchema"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform" exclude-result-prefixes="#all" version="3.0">

   <xsl:template match="x:description" mode="info-message" as="element()+">
      <!-- system-property() must be retrieved at run time -->
      <text>
         <xsl:text expand-text="yes">Testing with </xsl:text>
      </text>
      <value-of select="system-property('{x:known-UQName('xsl:product-name')}')"/>
      <text>
         <xsl:text> </xsl:text>
      </text>
      <value-of select="system-property('{x:known-UQName('xsl:product-version')}')"/>
   </xsl:template>

</xsl:stylesheet>