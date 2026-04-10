<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:x="http://www.jenitennison.com/xslt/xspec"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                exclude-result-prefixes="#all"
                version="3.0">

   <xsl:function name="x:label" as="element(x:label)">
      <xsl:param name="labelled" as="element()" />

      <!-- Create an x:label element without a prefix in its name. This prefix-less name aligns with
         the other elements in the test result report XML. -->
      <xsl:element name="label" namespace="{namespace-uri($labelled)}">
         <xsl:value-of select="($labelled/x:label, $labelled/@label)[1]" />
      </xsl:element>
   </xsl:function>

   <!-- Removes duplicate strings from a sequence of strings. (Removes a string if it appears
      in a prior position of the sequence.)
      Unlike fn:distinct-values(), the order of the returned sequence is stable.

      The xsl:function/xsl:sequence/@select attribute is similar to the XPath expression in
      "XPath and XQuery Functions and Operators 3.1" (W3C Recommendation 21 March 2017)
      > "D Other Functions (Non-Normative)" > "D.4 Illustrative user-written functions"
      > "D.4.5 eg:distinct-nodes-stable"
      http://www.w3.org/TR/xpath-functions-31/#func-distinct-nodes-stable
      except that this function processes strings, not nodes. 
   -->
   <xsl:function name="x:distinct-strings-stable" as="xs:string*">
      <xsl:param name="strings" as="xs:string*" />

      <xsl:sequence select="$strings[not(subsequence($strings, 1, position() - 1) = .)]"/>
   </xsl:function>

   <!--
      Returns the effective value of @xslt-version of the context element.

      $context is usually x:description or x:expect.
   -->
   <xsl:function as="xs:decimal" name="x:xslt-version">
      <xsl:param as="element()" name="context" />

      <xsl:sequence select="
            (
               $context/ancestor-or-self::*[@xslt-version][1]/@xslt-version,
               3.0
            )[1]"
       />
   </xsl:function>

   <!--
      Returns a lexical QName in the XSpec namespace. Usually 'x:local-name'.
      The prefix is taken from the context element's namespaces.
      If multiple namespace prefixes have the XSpec namespace URI,
         - The context element name's prefix is preferred.
         - If the context element's name is not in the XSpec namespace, the first prefix is used
           after sorting them in a way that the default namespace is preferred.
   -->
   <xsl:function as="xs:string" name="x:xspec-name">
      <xsl:param as="xs:string" name="local-name" />
      <xsl:param as="element()" name="context-element" />

      <xsl:variable as="xs:QName" name="context-node-name" select="node-name($context-element)" />

      <xsl:variable as="xs:string?" name="prefix">
         <xsl:choose>
            <xsl:when test="namespace-uri-from-QName($context-node-name) eq $x:xspec-namespace">
               <xsl:sequence select="prefix-from-QName($context-node-name)" />
            </xsl:when>

            <xsl:otherwise>
               <xsl:variable as="xs:string+" name="xspec-prefixes" select="
                     in-scope-prefixes($context-element)
                     [namespace-uri-for-prefix(., $context-element) eq $x:xspec-namespace]" />
               <xsl:sequence select="sort($xspec-prefixes)[1]" />
            </xsl:otherwise>
         </xsl:choose>
      </xsl:variable>

      <xsl:sequence select="($prefix[.], $local-name) => string-join(':')" />
   </xsl:function>

   <!-- Prefixes a diagnostic message with identifiable information of its originating element -->
   <xsl:template name="x:prefix-diag-message" as="xs:string">
      <xsl:context-item as="node()" use="required" />

      <xsl:param name="level" as="xs:string" select="'ERROR'" />
      <xsl:param name="message" as="xs:string" required="yes" />

      <xsl:variable name="owner-element" as="element()?" select="ancestor-or-self::x:*[1]" />
      <xsl:variable name="full-label" as="xs:string" select="
            $owner-element/ancestor-or-self::x:*[not(self::x:like or self::x:pending)]/x:label(.)
            => string-join(' ')
            => normalize-space()" />

      <xsl:value-of>
         <xsl:text expand-text="yes">{$level}</xsl:text>

         <xsl:for-each select="$owner-element">
            <!-- If prefixed, use lexical QName. If not prefixed, use URIQualifiedName. -->
            <xsl:variable name="owner-element-eqname" as="xs:string" select="
                  if (node-name() => prefix-from-QName()) then
                     name()
                  else
                     x:node-UQName(.)" />
            <xsl:text expand-text="yes"> in {$owner-element-eqname}</xsl:text>

            <xsl:for-each select="(@name, self::x:input/@port)[1]">
               <xsl:text expand-text="yes"> (named {.})</xsl:text>
            </xsl:for-each>

            <xsl:for-each select="
                  .[not(self::x:expect or self::x:scenario)]
                  ! x:label(.)
                  ! normalize-space()[. (: eliminate zero-length string :)]">
               <xsl:text expand-text="yes"> (labeled '{.}')</xsl:text>
            </xsl:for-each>
         </xsl:for-each>

         <xsl:for-each select="$full-label[. (: eliminate zero-length string :)]">
            <xsl:text> (</xsl:text>
            <xsl:if test="$owner-element[not(self::x:expect or self::x:scenario)]">
               <xsl:text>under </xsl:text>
            </xsl:if>
            <xsl:text expand-text="yes">'{.}')</xsl:text>
         </xsl:for-each>

         <xsl:text expand-text="yes">: {$message}</xsl:text>
      </xsl:value-of>
   </xsl:template>

</xsl:stylesheet>