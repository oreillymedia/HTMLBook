<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:x="http://www.jenitennison.com/xslt/xspec"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                exclude-result-prefixes="#all"
                version="3.0">

   <!--
      mode="x:assign-id"
      This mode assigns ID to x:scenario and x:expect
   -->
   <xsl:mode name="x:assign-id" on-multiple-match="fail" on-no-match="shallow-copy" />

   <xsl:template match="x:scenario | x:expect" as="element()" mode="x:assign-id">
      <xsl:copy>
         <xsl:attribute name="id">
            <xsl:apply-templates select="." mode="x:generate-id" />
         </xsl:attribute>
         <xsl:apply-templates select="attribute() | node()" mode="#current" />
      </xsl:copy>
   </xsl:template>

</xsl:stylesheet>