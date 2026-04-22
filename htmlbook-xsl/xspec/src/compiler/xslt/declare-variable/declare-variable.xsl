<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:x="http://www.jenitennison.com/xslt/xspec"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                exclude-result-prefixes="#all"
                version="3.0">

   <!--
      Generates XSLT variable declaration(s) from the current element.
      
      This template does not handle @static. It is just ignored. Enabling @static will create a
      usual non-static parameter or variable.
   -->
   <xsl:template name="x:declare-variable" as="element()+">
      <xsl:context-item as="element()" use="required" />

      <xsl:param name="comment" as="xs:string?" />
      <xsl:param name="uqname" as="xs:string" required="yes" />
      <xsl:param name="exclude" as="element()*" required="yes" />

      <!-- XSLT does not use this parameter -->
      <xsl:param name="as-global" as="xs:boolean" />

      <xsl:param name="as-param" as="xs:boolean" required="yes" />
      <xsl:param name="temp-doc-uqname" as="xs:string?" required="yes" />

      <xsl:if test="$temp-doc-uqname">
         <xsl:element name="xsl:variable" namespace="{$x:xsl-namespace}">
            <xsl:attribute name="name" select="$temp-doc-uqname" />
            <xsl:attribute name="as" select="'document-node()'" />

            <xsl:choose>
               <xsl:when test="@href">
                  <xsl:attribute name="select">
                     <xsl:text expand-text="yes">doc({@href => resolve-uri(base-uri()) => x:quote-with-apos()})</xsl:text>
                  </xsl:attribute>
               </xsl:when>

               <xsl:otherwise>
                  <xsl:element name="xsl:document" namespace="{$x:xsl-namespace}">
                     <xsl:apply-templates select="node() except $exclude" mode="x:node-constructor" />
                  </xsl:element>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:element>
      </xsl:if>

      <xsl:element name="xsl:{if ($as-param) then 'param' else 'variable'}"
         namespace="{$x:xsl-namespace}">
         <!-- @as or @select may use namespace prefixes. @select may use the default namespace such
            as xs:QName('foo'). -->
         <xsl:if test="@as or @select">
            <xsl:sequence select="x:copy-of-namespaces(.)" />
         </xsl:if>

         <xsl:attribute name="name" select="$uqname" />
         <xsl:sequence select="@as" />

         <xsl:choose>
            <xsl:when test="$temp-doc-uqname">
               <xsl:variable name="selection" as="xs:string" select="x:selection-from-doc(current())"/>
               <xsl:attribute name="select">
                  <xsl:text expand-text="yes">${$temp-doc-uqname} ! ( {$selection} )</xsl:text>
               </xsl:attribute>
            </xsl:when>

            <xsl:when test="empty(@as) and empty(@select)">
               <!--
                  Prevent the variable from being an unexpected zero-length string.
                  See https://www.w3.org/TR/xslt-30/#variable-values for mention of
                  zero-length string under these attribute conditions.
               -->
               <xsl:attribute name="select" select="'()'" />
            </xsl:when>

            <xsl:when test="self::x:input[@select] or self::x:expect[@port][not(@test)][@select]">
               <!--
                  Wrap each wrappable node. We reach this condition in a test for XProc and
                  the element uses @select alone. (Use of @select with @href or child nodes
                  reaches the xsl:when block for $temp-doc-uqname.)

                  Not adding use-when="$test-type eq 'xproc'" because this module is referenced
                  from multiple top-level stylesheets, not all of which define $test-type.
                  The match pattern is specific to XProc tests due to x:input and x:expect[@port].
               -->
               <xsl:variable name="selection" as="xs:string" select="x:selection-from-doc(current())"/>
               <xsl:attribute name="select" select="$selection"/>
            </xsl:when>

            <xsl:otherwise>
               <xsl:sequence select="@select" />
            </xsl:otherwise>
         </xsl:choose>

         <xsl:where-populated>
            <xsl:comment select="$comment" />
         </xsl:where-populated>
      </xsl:element>
   </xsl:template>

</xsl:stylesheet>