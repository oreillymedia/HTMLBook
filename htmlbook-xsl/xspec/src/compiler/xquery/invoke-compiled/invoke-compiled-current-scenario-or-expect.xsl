<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:local="urn:x-xspec:compiler:xquery:invoke-compiled:invoke-compiled-current-scenario-or-expect:local"
                xmlns:x="http://www.jenitennison.com/xslt/xspec"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                exclude-result-prefixes="#all"
                version="3.0">

   <!--
      Generates an invocation of the function compiled from x:scenario or x:expect.
   -->
   <xsl:template name="x:invoke-compiled-current-scenario-or-expect" as="text()+">
      <!-- Context item is x:scenario or x:expect -->
      <xsl:context-item as="element()" use="required" />

      <!-- URIQualifiedNames of the variables that will be passed as the parameters to the compiled
         x:scenario or x:expect being invoked.
         Their order must be stable, because they are passed to a function. -->
      <xsl:param name="with-param-uqnames" as="xs:string*" required="yes" />

      <xsl:param name="tunnel_variable-name-of-actual-result-report" as="xs:string?" tunnel="yes" />

      <xsl:text expand-text="yes">let ${local:variable-name-of-scenario-or-expect(.)} := local:{@id}(&#x0A;</xsl:text>
      <xsl:for-each select="$with-param-uqnames">
         <xsl:text expand-text="yes">${.}</xsl:text>
         <xsl:if test="position() ne last()">
            <xsl:text>,</xsl:text>
         </xsl:if>
         <xsl:text>&#x0A;</xsl:text>
      </xsl:for-each>
      <xsl:text>)&#x0A;</xsl:text>

      <!-- If there are no following-sibling (taking x:pending into account) x:scenario or x:expect
         elements, then return all the variables that have been returned from sibling-or-self
         (again, taking x:pending into account) x:scenario or x:expect. Precede them with the
         variable of the actual result report. -->

      <xsl:variable name="sibling-or-self" as="element()+"
         select="
            ancestor::element()[self::x:description or self::x:scenario][1]
            /(. | x:pending)
            /(x:scenario | x:expect)" />

      <xsl:if test="$sibling-or-self[. >> current()] => empty()">
         <xsl:text>return (&#x0A;</xsl:text>

         <xsl:for-each select="$tunnel_variable-name-of-actual-result-report">
            <xsl:text expand-text="yes">${.},&#x0A;</xsl:text>
         </xsl:for-each>

         <xsl:for-each select="$sibling-or-self">
            <xsl:text expand-text="yes">${local:variable-name-of-scenario-or-expect(.)}</xsl:text>
            <xsl:if test="position() ne last()">
               <xsl:text>,</xsl:text>
            </xsl:if>
            <xsl:text>&#x0A;</xsl:text>
         </xsl:for-each>

         <xsl:text>)&#x0A;</xsl:text>
      </xsl:if>
   </xsl:template>

   <!--
      Local functions
   -->

   <xsl:function name="local:variable-name-of-scenario-or-expect" as="xs:string">
      <xsl:param name="scenario-or-expect" as="element()" />

      <xsl:sequence select="'local:returned-from-' || $scenario-or-expect/@id" />
   </xsl:function>

</xsl:stylesheet>