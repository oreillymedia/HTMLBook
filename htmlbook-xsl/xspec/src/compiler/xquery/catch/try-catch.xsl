<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:x="http://www.jenitennison.com/xslt/xspec"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                exclude-result-prefixes="#all"
                version="3.0">

   <xsl:template name="x:try-catch" as="text()+">
      <xsl:context-item use="absent" />

      <xsl:param name="instruction" as="text()+" required="yes" />

      <xsl:text>try {&#x0A;</xsl:text>
      <xsl:sequence select="$instruction" />
      <xsl:text>}&#x0A;</xsl:text>

      <xsl:text>catch * {&#x0A;</xsl:text>
      <xsl:text>map {&#x0A;</xsl:text>
      <xsl:text>'err': map {&#x0A;</xsl:text>

      <!-- Variables available within the catch clause:
         https://www.w3.org/TR/xquery-31/#id-try-catch -->
      <xsl:for-each
         select="'code', 'description', 'value', 'module', 'line-number', 'column-number', 'additional'">
         <xsl:text expand-text="yes">'{.}': ${x:known-UQName('err:' || .)}</xsl:text>
         <xsl:if test="position() ne last()">
            <xsl:text>,</xsl:text>
         </xsl:if>
         <xsl:text>&#x0A;</xsl:text>
      </xsl:for-each>

      <!-- End of 'err' map -->
      <xsl:text>}&#x0A;</xsl:text>

      <!-- End of $x:result map -->
      <xsl:text>}&#x0A;</xsl:text>

      <!-- End of catch -->
      <xsl:text>}&#x0A;</xsl:text>
   </xsl:template>

</xsl:stylesheet>