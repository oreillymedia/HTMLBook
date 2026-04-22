<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:x="http://www.jenitennison.com/xslt/xspec"
   xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   exclude-result-prefixes="#all" version="3.0">

   <xsl:function name="x:selection-from-doc" as="xs:string">
      <xsl:param name="element" as="element()"/>
      <xsl:sequence select="
            (
            $element/@select,
            '.'[$element/@href],
            'node()'
            )[1]"/>
   </xsl:function>

</xsl:stylesheet>