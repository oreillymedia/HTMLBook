<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:x="http://www.jenitennison.com/xslt/xspec"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                exclude-result-prefixes="#all"
                version="3.0">

   <!-- Generates a gateway from x:scenario to System Under Test.
      The actual instruction to enter SUT is provided by the caller. The instruction
      should not contain other actions. -->
   <xsl:template name="x:enter-sut" as="node()+">
      <xsl:context-item as="element(x:scenario)" use="required" />

      <xsl:param name="instruction" as="node()+" required="yes" />

      <xsl:choose>
         <xsl:when test="x:yes-no-synonym(ancestor-or-self::*[@catch][1]/@catch, false())">
            <xsl:call-template name="x:try-catch">
               <xsl:with-param name="instruction" select="$instruction" />
            </xsl:call-template>
         </xsl:when>
         <xsl:otherwise>
            <xsl:sequence select="$instruction" />
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>

</xsl:stylesheet>