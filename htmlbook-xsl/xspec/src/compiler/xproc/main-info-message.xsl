<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.w3.org/1999/XSL/TransformAlias"
   xmlns:p="http://www.w3.org/ns/xproc"
   xmlns:pf="http://www.jenitennison.com/xslt/xspec/xproc/steps/wrap-standard-functions"
   xmlns:x="http://www.jenitennison.com/xslt/xspec" xmlns:xs="http://www.w3.org/2001/XMLSchema"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform" exclude-result-prefixes="#all" version="3.0">
   
   <xsl:template match="x:description" mode="info-message" as="element()+">
      <xsl:apply-imports/>
      <text>
         <xsl:text> and </xsl:text>
      </text>
      <text>
         <xsl:text>XML Calabash</xsl:text>
      </text>
      <text>
         <xsl:text> </xsl:text>
      </text>
      <!-- pf:system-property() must be retrieved at run time -->
      <value-of select="{x:known-UQName('pf:system-property')}( map{{'property': '{x:known-UQName('p:product-version')}'}} )?result"/>
      
   </xsl:template>
   
</xsl:stylesheet>