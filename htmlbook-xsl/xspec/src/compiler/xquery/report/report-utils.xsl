<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:x="http://www.jenitennison.com/xslt/xspec"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                exclude-result-prefixes="#all"
                version="3.0">

   <xsl:template name="x:wrap-node-constructors-and-undeclare-default-ns" as="node()+">
      <xsl:context-item use="absent" />

      <xsl:param name="wrapper-name" as="xs:string" required="yes" />
      <xsl:param name="node-constructors" as="node()+" required="yes" />

      <xsl:text>element { QName('', '</xsl:text>
      <xsl:value-of select="$wrapper-name" />
      <xsl:text>') } {&#x0A;</xsl:text>
      <xsl:sequence select="$node-constructors" />
      <xsl:text>}</xsl:text>
   </xsl:template>

   <xsl:template name="x:call-report-sequence" as="text()">
      <!-- Context item is x:scenario or x:expect, but not used -->
      <xsl:context-item use="absent" />

      <xsl:param name="sequence-variable-eqname" as="xs:string" required="yes" />
      <xsl:param name="report-name" as="xs:string" select="'result'" />

      <xsl:text expand-text="yes">{x:known-UQName('rep:report-sequence')}(${$sequence-variable-eqname}, '{$report-name}')</xsl:text>
   </xsl:template>

</xsl:stylesheet>