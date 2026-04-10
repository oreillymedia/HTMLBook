<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:x="http://www.jenitennison.com/xslt/xspec"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                exclude-result-prefixes="#all"
                version="3.0">

   <xsl:template name="x:compile-helpers" as="element()*">
      <xsl:context-item as="element(x:description)" use="required" />

      <xsl:for-each select="x:helper[@package-name | @stylesheet]">
         <xsl:choose>
            <xsl:when test="@package-name">
               <xsl:element name="xsl:use-package" namespace="{$x:xsl-namespace}">
                  <xsl:attribute name="name" select="@package-name" />
                  <xsl:sequence select="@package-version" />
               </xsl:element>
            </xsl:when>
            <xsl:when test="@stylesheet">
               <xsl:element name="xsl:import" namespace="{$x:xsl-namespace}">
                  <xsl:attribute name="href" select="@stylesheet" />
               </xsl:element>
            </xsl:when>
         </xsl:choose>
      </xsl:for-each>
   </xsl:template>

</xsl:stylesheet>