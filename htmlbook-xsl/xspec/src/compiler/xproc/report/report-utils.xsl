<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:x="http://www.jenitennison.com/xslt/xspec"
   xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   exclude-result-prefixes="#all" version="3.0">

   <!-- If $x:result is scoped to a particular output port of the step, record that so the scoped
      data, not the map of all ports' outputs, appears in the test result report. -->
   <xsl:template name="x:record-port-specific-result" as="element(x:port-specific)">
      <xsl:context-item as="element(x:expect)" use="required"/>
      <xsl:element name="port-specific" namespace="http://www.jenitennison.com/xslt/xspec">
         <xsl:call-template name="x:call-report-sequence">
            <xsl:with-param name="sequence-variable-eqname" select="x:known-UQName('x:result')"/>
         </xsl:call-template>
      </xsl:element>
   </xsl:template>
</xsl:stylesheet>