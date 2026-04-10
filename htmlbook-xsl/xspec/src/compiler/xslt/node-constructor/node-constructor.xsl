<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:x="http://www.jenitennison.com/xslt/xspec"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                exclude-result-prefixes="#all"
                version="3.0">

   <!--
      mode="x:node-constructor"
   -->
   <xsl:mode name="x:node-constructor" on-multiple-match="fail" on-no-match="fail" />

   <xsl:template match="element()" as="element(xsl:element)" mode="x:node-constructor">
      <xsl:element name="xsl:element" namespace="{$x:xsl-namespace}">
         <xsl:attribute name="name" select="name()" />
         <xsl:attribute name="namespace" select="namespace-uri()" />

         <xsl:apply-templates
            select="
               x:copy-of-additional-namespaces(.),
               attribute(),
               node()"
            mode="#current" />
      </xsl:element>
   </xsl:template>

   <xsl:template match="namespace-node()" as="element(xsl:namespace)" mode="x:node-constructor">
      <xsl:element name="xsl:namespace" namespace="{$x:xsl-namespace}">
         <xsl:attribute name="name" select="name()" />
         <xsl:value-of select="." />
      </xsl:element>
   </xsl:template>

   <xsl:template match="attribute()" as="element(xsl:attribute)" mode="x:node-constructor">
      <xsl:variable name="maybe-avt" as="xs:boolean" select="x:is-user-content(.)" />

      <xsl:element name="xsl:attribute" namespace="{$x:xsl-namespace}">
         <xsl:if test="$maybe-avt">
            <!-- AVT may use namespace prefixes and/or the default namespace such as
               xs:QName('foo') -->
            <xsl:sequence select="parent::element() => x:copy-of-namespaces()" />
         </xsl:if>

         <xsl:attribute name="name" select="name()" />
         <xsl:attribute name="namespace" select="namespace-uri()" />

         <xsl:choose>
            <xsl:when test="$maybe-avt">
               <xsl:attribute name="select">'', ''</xsl:attribute>
               <xsl:attribute name="separator" select="." />
            </xsl:when>

            <xsl:otherwise>
               <xsl:value-of select="." />
            </xsl:otherwise>
         </xsl:choose>
      </xsl:element>
   </xsl:template>

   <xsl:template match="text()" as="element(xsl:text)" mode="x:node-constructor">
      <xsl:element name="xsl:text" namespace="{$x:xsl-namespace}">
         <xsl:if test="x:is-user-content(.)">
            <xsl:if test="parent::x:text/@expand-text/x:yes-no-synonym(.)">
               <!-- TVT may use namespace prefixes and/or the default namespace such as
                  xs:QName('foo') -->
               <xsl:sequence select="x:copy-of-namespaces(parent::x:text)" />
            </xsl:if>

            <xsl:sequence select="parent::x:text/@expand-text" />
         </xsl:if>

         <xsl:sequence select="." />
      </xsl:element>
   </xsl:template>

   <xsl:template match="processing-instruction()" as="element(xsl:processing-instruction)"
      mode="x:node-constructor">
      <xsl:element name="xsl:processing-instruction" namespace="{$x:xsl-namespace}">
         <xsl:attribute name="name" select="name()" />

         <xsl:value-of select="." />
      </xsl:element>
   </xsl:template>

   <xsl:template match="comment()" as="element(xsl:comment)" mode="x:node-constructor">
      <xsl:element name="xsl:comment" namespace="{$x:xsl-namespace}">
         <xsl:value-of select="." />
      </xsl:element>
   </xsl:template>

   <!-- x:text represents its child text node -->
   <xsl:template match="x:text" as="element(xsl:text)" mode="x:node-constructor">
      <!-- Unwrap -->
      <xsl:apply-templates mode="#current" />
   </xsl:template>

</xsl:stylesheet>