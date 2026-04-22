<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:x="http://www.jenitennison.com/xslt/xspec"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                exclude-result-prefixes="#all"
                version="3.0">

   <!-- @character specifies intermediate characters for mimicking @disable-output-escaping.
      For the XQuery XSpec, these Private Use Area characters should be considered as reserved by
      x:disable-escaping.
      This mapping should be in sync with t:escape-markup in ../harnesses/harness-lib.xpl. -->
   <xsl:character-map name="x:disable-escaping">
      <xsl:output-character character="&#xE801;" string="&lt;" />
      <xsl:output-character character="&#xE803;" string="&gt;" />
   </xsl:character-map>

   <!-- Replaces < > characters with the reserved characters.
      The serializer will convert those reserved characters back to < > characters,
      provided that x:disable-escaping character map is specified as a serialization
      parameter.
      Returns a zero-length string if the input is an empty sequence. -->
   <xsl:function name="x:disable-escaping" as="xs:string">
      <xsl:param name="input" as="xs:string?" />

      <xsl:sequence select="
         doc('')
         /xsl:*
         /xsl:character-map[@name eq 'x:disable-escaping']
         /translate(
            $input,
            string-join(xsl:output-character/@string),
            string-join(xsl:output-character/@character)
         )"/>
   </xsl:function>

</xsl:stylesheet>