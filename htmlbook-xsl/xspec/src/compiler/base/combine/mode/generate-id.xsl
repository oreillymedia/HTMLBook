<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:x="http://www.jenitennison.com/xslt/xspec"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                exclude-result-prefixes="#all"
                version="3.0">

   <!--
      mode="x:generate-id"
      Generates the ID of current x:scenario or x:expect.
      These default templates assume that all the scenarios have already been gathered and unshared.
      So the default ID may not always be usable for backtracking. For such backtracking purposes,
      override these default templates and implement your own ID generation. The generated ID must
      be castable as xs:NCName, because ID is used as a part of local name.
      Note that when this mode is applied, all the scenarios have been gathered and unshared in a
      single document, but the document still does not have /x:description.
   -->
   <xsl:mode name="x:generate-id" on-multiple-match="fail" on-no-match="fail" />

   <xsl:template match="x:scenario" as="xs:string" mode="x:generate-id">
      <!-- Some ID generators may depend on @xspec, although this default generator doesn't. -->
      <xsl:if test="empty(@xspec)">
         <xsl:message terminate="yes">
            <xsl:call-template name="x:prefix-diag-message">
               <xsl:with-param name="message" select="'@xspec not exist when generating ID.'" />
            </xsl:call-template>
         </xsl:message>
      </xsl:if>

      <xsl:variable name="ancestor-or-self-tokens" as="xs:string+">
         <xsl:for-each select="ancestor-or-self::x:scenario">
            <!-- Find preceding sibling x:scenario, taking x:pending into account -->

            <!-- Parent document node or x:scenario.
               Note:
               - x:pending may exist in between.
               - In the current mode, the document still does not have /x:description. -->
            <xsl:variable name="parent-document-node-or-scenario" as="node()"
               select="ancestor::node()[self::document-node() or self::x:scenario][1]" />

            <xsl:variable name="preceding-sibling-scenarios" as="element(x:scenario)*"
               select="$parent-document-node-or-scenario/descendant::x:scenario
                  [ancestor::node()[self::document-node() or self::x:scenario][1] is $parent-document-node-or-scenario]
                  [current() >> .]" />

            <xsl:sequence select="local-name() || (count($preceding-sibling-scenarios) + 1)" />
         </xsl:for-each>
      </xsl:variable>

      <xsl:sequence select="string-join($ancestor-or-self-tokens, '-')" />
   </xsl:template>

   <xsl:template match="x:expect" as="xs:string" mode="x:generate-id">
      <!-- Find preceding sibling x:expect, taking x:pending into account -->
      <xsl:variable name="scenario" as="element(x:scenario)" select="ancestor::x:scenario[1]" />
      <xsl:variable name="preceding-sibling-expects" as="element(x:expect)*"
         select="$scenario/descendant::x:expect
            [ancestor::x:scenario[1] is $scenario]
            [current() >> .]" />

      <xsl:variable name="scenario-id" as="xs:string">
         <xsl:apply-templates select="$scenario" mode="#current" />
      </xsl:variable>

      <xsl:sequence select="$scenario-id || '-' || local-name() || (count($preceding-sibling-expects) + 1)" />
   </xsl:template>

</xsl:stylesheet>