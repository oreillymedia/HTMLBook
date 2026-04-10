<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:x="http://www.jenitennison.com/xslt/xspec"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                exclude-result-prefixes="#all"
                version="3.0">

   <!--
      Returns true or false based on "yes" or "no",
      accepting ("true" or "false") and ("1" or "0") as synonyms.
   -->
   <xsl:function as="xs:boolean" name="x:yes-no-synonym">
      <xsl:param as="xs:string" name="input" />

      <xsl:choose>
         <xsl:when test="$input = ('yes', 'true', '1')">
            <xsl:sequence select="true()" />
         </xsl:when>
         <xsl:when test="$input = ('no', 'false', '0')">
            <xsl:sequence select="false()" />
         </xsl:when>
      </xsl:choose>
   </xsl:function>

   <!--
      x:yes-no-synonym#1 plus default value in case of empty sequence
   -->
   <xsl:function as="xs:boolean" name="x:yes-no-synonym">
      <xsl:param as="xs:string?" name="input" />
      <xsl:param as="xs:boolean" name="default" />

      <xsl:sequence
         select="
            if (exists($input)) then
               x:yes-no-synonym($input)
            else
               $default"
       />
   </xsl:function>

</xsl:stylesheet>