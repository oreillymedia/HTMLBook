<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:local="urn:x-xspec:compiler:xquery:declare-variable:declare-variable:local"
                xmlns:x="http://www.jenitennison.com/xslt/xspec"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                exclude-result-prefixes="#all"
                version="3.0">

   <!--
      Generates XQuery variable declaration(s) from the current element.
      
      This template rejects @static=yes.
   -->

   <xsl:template name="x:declare-variable" as="node()+">
      <xsl:context-item as="element()" use="required" />

      <xsl:param name="comment" as="xs:string?" />
      <xsl:param name="uqname" as="xs:string" required="yes" />
      <xsl:param name="exclude" as="element(x:label)?" required="yes" />
      <xsl:param name="as-global" as="xs:boolean" required="yes" />

      <!-- XQuery does not use this parameter.
         TODO: If true, declare an XQuery external variable. (But it isn't worth implementing.
         External variables are of no use in XSpec.) -->
      <xsl:param name="as-param" as="xs:boolean" />

      <xsl:param name="temp-doc-uqname" as="xs:string?" required="yes" />

      <!-- XQuery-specific checks -->
      <xsl:call-template name="local:check-xquery-vardecl" />

      <!--
         Output
            declare variable $TEMPORARYNAME-doc as document-node() := DOCUMENT;
         or
                         let $TEMPORARYNAME-doc as document-node() := DOCUMENT
         
         where DOCUMENT is
            doc('RESOLVED-HREF')
         or
            document { NODE-CONSTRUCTORS }
      -->
      <xsl:if test="$temp-doc-uqname">
         <xsl:call-template name="x:declare-or-let-variable">
            <xsl:with-param name="as-global" select="$as-global" />
            <xsl:with-param name="uqname" select="$temp-doc-uqname" />
            <xsl:with-param name="type" select="'document-node()'" />
            <xsl:with-param name="value" as="node()+">
               <xsl:choose>
                  <xsl:when test="@href">
                     <xsl:text expand-text="yes">doc({@href => resolve-uri(base-uri()) => x:quote-with-apos()})</xsl:text>
                  </xsl:when>

                  <xsl:otherwise>
                     <xsl:text>document {&#x0A;</xsl:text>
                     <xsl:call-template name="x:zero-or-more-node-constructors">
                        <xsl:with-param name="nodes" select="node() except $exclude" />
                     </xsl:call-template>
                     <xsl:text>&#x0A;</xsl:text>
                     <xsl:text>}</xsl:text>
                  </xsl:otherwise>
               </xsl:choose>
            </xsl:with-param>
         </xsl:call-template>
      </xsl:if>

      <!--
         Output
            declare variable ${$name} as TYPE := SELECTION;
         or
                         let ${$name} as TYPE := SELECTION
         
         where SELECTION is
            ( $TEMPORARYNAME-doc ! ( EXPRESSION ) )
         or
            ( EXPRESSION )
      -->
      <xsl:call-template name="x:declare-or-let-variable">
         <xsl:with-param name="as-global" select="$as-global" />
         <xsl:with-param name="uqname" select="$uqname" />
         <xsl:with-param name="type" select="x:lexical-to-UQName-in-sequence-type(., 'as')" />
         <xsl:with-param name="value" as="text()?">
            <xsl:choose>
               <xsl:when test="$temp-doc-uqname">
                  <xsl:variable name="selection" as="xs:string"
                     select="(@select, '.'[current()/@href], 'node()')[1]" />
                  <xsl:text expand-text="yes">${$temp-doc-uqname} ! ( {x:disable-escaping($selection)} )</xsl:text>
               </xsl:when>

               <xsl:when test="@select">
                  <xsl:value-of select="x:disable-escaping(@select)" />
               </xsl:when>
            </xsl:choose>
         </xsl:with-param>
         <xsl:with-param name="comment" select="$comment" />
      </xsl:call-template>
   </xsl:template>

   <!--
      Outputs
         declare variable $NAME as TYPE := ( VALUE );
      or
                      let $NAME as TYPE := ( VALUE )
   -->
   <xsl:template name="x:declare-or-let-variable" as="node()+">
      <xsl:context-item use="absent" />

      <xsl:param name="as-global" as="xs:boolean" required="yes" />
      <xsl:param name="uqname" as="xs:string" required="yes" />
      <xsl:param name="type" as="xs:string?" required="yes" />
      <xsl:param name="value" as="node()*" required="yes" />
      <xsl:param name="comment" as="xs:string?" />

      <xsl:choose>
         <xsl:when test="$as-global">
            <xsl:text>declare variable</xsl:text>
         </xsl:when>
         <xsl:otherwise>
            <xsl:text>let</xsl:text>
         </xsl:otherwise>
      </xsl:choose>

      <xsl:text expand-text="yes"> ${$uqname}</xsl:text>

      <xsl:if test="$type">
         <xsl:text expand-text="yes"> as {$type}</xsl:text>
      </xsl:if>

      <xsl:if test="$comment">
         <xsl:text expand-text="yes"> (:{$comment}:)</xsl:text>
      </xsl:if>

      <xsl:text> := (&#x0A;</xsl:text>

      <xsl:choose>
         <xsl:when test="$value">
            <xsl:sequence select="$value" />
         </xsl:when>
         <xsl:otherwise>
            <xsl:text>()</xsl:text>
         </xsl:otherwise>
      </xsl:choose>

      <xsl:text>&#x0A;)</xsl:text>

      <xsl:if test="$as-global">
         <xsl:text>;</xsl:text>
      </xsl:if>
      <xsl:text>&#10;</xsl:text>
   </xsl:template>

   <!--
      Local templates
   -->

   <xsl:template name="local:check-xquery-vardecl" as="empty-sequence()">
      <xsl:context-item as="element()" use="required" />

      <!-- Reject x:param if it is analogous to /xsl:stylesheet/xsl:param -->
      <xsl:if test="self::x:param[parent::x:description or parent::x:scenario]">
         <xsl:message terminate="yes">
            <xsl:call-template name="x:prefix-diag-message">
               <xsl:with-param name="message">
                  <!-- x:combine() removes the name prefix from x:description. That's why
                     URIQualifiedName is used. -->
                  <xsl:text expand-text="yes">{parent::element() => x:node-UQName()} has {name()}, which is not supported for XQuery.</xsl:text>
               </xsl:with-param>
            </xsl:call-template>
         </xsl:message>
      </xsl:if>

      <!-- Reject @static=yes -->
      <xsl:if test="x:yes-no-synonym(@static, false())">
         <xsl:message terminate="yes">
            <xsl:call-template name="x:prefix-diag-message">
               <xsl:with-param name="message" select="'Enabling @static is not supported for XQuery.'" />
            </xsl:call-template>
         </xsl:message>
      </xsl:if>
   </xsl:template>

</xsl:stylesheet>