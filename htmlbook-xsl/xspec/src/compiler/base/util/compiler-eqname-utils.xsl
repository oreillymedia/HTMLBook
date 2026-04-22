<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:equtil="urn:x-xspec:compiler:base:util:compiler-eqname-utils"
                xmlns:local="urn:x-xspec:compiler:base:util:compiler-eqname-utils:local"
                xmlns:x="http://www.jenitennison.com/xslt/xspec"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                exclude-result-prefixes="#all"
                version="3.0">

   <!--
      Resolves EQName (either URIQualifiedName or lexical QName, the latter is
      resolved without using the default namespace) to xs:QName.
      
      Unlike fn:resolve-QName(), this function can handle XSLT names in many cases. See
      "Notes" in https://www.w3.org/TR/xpath-functions-31/#func-resolve-QName or more
      specifically p.866 of XSLT 2.0 and XPath 2.0 Programmer's Reference, 4th Edition.
   -->
   <xsl:function as="xs:QName" name="x:resolve-EQName-ignoring-default-ns">
      <xsl:param as="xs:string" name="eqname" />
      <xsl:param as="element()" name="element" />

      <xsl:choose>
         <xsl:when test="starts-with($eqname, 'Q{')">
            <xsl:sequence select="local:resolve-UQName($eqname)" />
         </xsl:when>

         <xsl:otherwise>
            <!-- To suppress "SXWN9000: ... QName has null namespace but non-empty prefix",
               do not pass the lexical QName directly to fn:QName(). (xspec/xspec#826) -->
            <xsl:variable as="xs:QName" name="qname-taking-default-ns"
               select="resolve-QName($eqname, $element)" />

            <xsl:sequence
               select="
                  if (prefix-from-QName($qname-taking-default-ns)) then
                     $qname-taking-default-ns
                  else
                     QName('', local-name-from-QName($qname-taking-default-ns))"
             />
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>

   <!--
      Resolves EQName (either URIQualifiedName or lexical QName, the latter is
      resolved without using the default namespace) to xs:QName
      and returns an XPath expression of fn:QName() which represents the resolved xs:QName.
   -->
   <xsl:function as="xs:string" name="x:QName-expression-from-EQName-ignoring-default-ns">
      <xsl:param as="xs:string" name="eqname" />
      <xsl:param as="element()" name="element" />

      <xsl:variable as="xs:QName" name="qname"
         select="x:resolve-EQName-ignoring-default-ns($eqname, $element)" />

      <xsl:sequence select="x:QName-expression($qname)" />
   </xsl:function>

   <!--
      Expands EQName (either URIQualifiedName or lexical QName, the latter is
      resolved without using the default namespace) to URIQualifiedName.
   -->
   <xsl:function as="xs:string" name="x:UQName-from-EQName-ignoring-default-ns">
      <xsl:param as="xs:string" name="eqname" />
      <xsl:param as="element()" name="element" />

      <xsl:sequence select="
            $eqname
            => x:resolve-EQName-ignoring-default-ns($element)
            => x:UQName-from-QName()" />
   </xsl:function>

   <!--
      Local components
   -->

   <!--
      Regular expression to capture NCName
      
      Based on https://github.com/xspec/xspec/blob/fb7f63d8190a5ccfea5c6a21b2ee142164a7c92c/src/schemas/xspec.rnc#L329
   -->
   <xsl:variable as="xs:string" name="equtil:capture-NCName">([\i-[:]][\c-[:]]*)</xsl:variable>

   <!--
      Resolves URIQualifiedName to xs:QName
   -->
   <xsl:function as="xs:QName" name="local:resolve-UQName">
      <xsl:param as="xs:string" name="uqname" />

      <xsl:variable as="xs:string" name="regex">
         <xsl:value-of xml:space="preserve">
            <!-- based on https://github.com/xspec/xspec/blob/fb7f63d8190a5ccfea5c6a21b2ee142164a7c92c/src/schemas/xspec.rnc#L329 -->
            ^
               Q\{
                  ([^\{\}]*)                                   <!-- group 1: URI -->
               \}
               <xsl:value-of select="$equtil:capture-NCName" /> <!-- group 2: local name -->
            $
         </xsl:value-of>
      </xsl:variable>

      <xsl:analyze-string flags="x" regex="{$regex}" select="$uqname">
         <xsl:matching-substring>
            <xsl:sequence select="QName(regex-group(1), regex-group(2))" />
         </xsl:matching-substring>
      </xsl:analyze-string>
   </xsl:function>

</xsl:stylesheet>
