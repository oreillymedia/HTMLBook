<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:x="http://www.jenitennison.com/xslt/xspec"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                exclude-result-prefixes="#all"
                version="3.0">

   <!--
      mode="x:force-focus"
      This mode enforces focus on specific instances of x:scenario and removes focus from the others
      if $force-focus is specified.
   -->
   <xsl:mode name="x:force-focus" on-multiple-match="fail" on-no-match="shallow-copy" />

   <!-- Enforce focus on or remove focus from x:scenario -->
   <xsl:template match="x:scenario[$force-focus]" as="element(x:scenario)" mode="x:force-focus">
      <xsl:copy>
         <xsl:if test="contains-token($force-focus, @id)">
            <xsl:attribute name="focus" select="'force focus'" />
         </xsl:if>
         <xsl:apply-templates select="attribute() except @focus" mode="#current" />

         <xsl:apply-templates select="node()" mode="#current" />
      </xsl:copy>
   </xsl:template>

</xsl:stylesheet>