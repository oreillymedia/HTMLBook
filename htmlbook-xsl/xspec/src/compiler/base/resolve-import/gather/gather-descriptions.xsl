<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:local="urn:x-xspec:compiler:base:resolve-import:gather:gather-descriptions:local"
                xmlns:x="http://www.jenitennison.com/xslt/xspec"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                exclude-result-prefixes="#all"
                version="3.0">

   <!--
      Gather x:description
   -->

   <xsl:function name="x:gather-descriptions" as="element(x:description)+">
      <xsl:param name="visit" as="element(x:description)+"/>

      <!-- "$visit/x:import" without sorting -->
      <xsl:variable name="imports" as="element(x:import)*"
                    select="local:distinct-nodes-stable($visit ! x:import)" />

      <!-- "document($imports/@href)" (and error check) without sorting -->
      <xsl:variable name="docs" as="document-node(element(x:description))*"
                    select="local:distinct-nodes-stable(
                               $imports
                               ! (document(@href) treat as document-node(element(x:description)))
                            )" />

      <!-- "$docs/x:description" without sorting -->
      <xsl:variable name="imported" as="element(x:description)*"
                    select="local:distinct-nodes-stable($docs ! x:description)" />

      <!-- "$imported except $visit" without sorting -->
      <xsl:variable name="visited-actual-uris" as="xs:anyURI+"
         select="$visit ! x:document-actual-uri(/)" />
      <xsl:variable name="imported-except-visit" as="element(x:description)*"
         select="
            $imported[empty(. intersect $visit)]

            (: xspec/xspec#987 :)
            [not(x:document-actual-uri(/) = $visited-actual-uris)]" />

      <xsl:choose>
         <xsl:when test="empty($imported-except-visit)">
            <xsl:sequence select="$visit"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:sequence select="($visit, $imported-except-visit) => x:gather-descriptions()" />
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>

   <!--
      Local functions
   -->

   <xsl:include href="distinct-nodes-stable.xsl"/>

</xsl:stylesheet>