<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:x="http://www.jenitennison.com/xslt/xspec"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                exclude-result-prefixes="#all"
                version="3.0">

   <!--
      Generates an invocation of the template compiled from x:scenario or x:expect.
   -->
   <xsl:template name="x:invoke-compiled-current-scenario-or-expect" as="element(xsl:call-template)">
      <!-- Context item is x:scenario or x:expect -->
      <xsl:context-item as="element()" use="required" />

      <!-- URIQualifiedNames of the variables that will be passed as the parameters to the compiled
         x:scenario or x:expect being invoked. Names and contents of the variables are passed
         through unchanged. -->
      <xsl:param name="with-param-uqnames" as="xs:string*" required="yes" />

      <xsl:element name="xsl:call-template" namespace="{$x:xsl-namespace}">
         <xsl:attribute name="name" select="x:known-UQName('x:' || @id)" />

         <xsl:if test="self::x:scenario">
            <xsl:processing-instruction name="origin" select="local-name()" />
         </xsl:if>

         <xsl:for-each select="$with-param-uqnames">
            <xsl:element name="xsl:with-param" namespace="{$x:xsl-namespace}">
               <xsl:attribute name="name" select="." />
               <xsl:attribute name="select" select="'$' || ." />
            </xsl:element>
         </xsl:for-each>
      </xsl:element>
   </xsl:template>

</xsl:stylesheet>