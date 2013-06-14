<xsl:stylesheet version="1.0"
		xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:l="http://docbook.sourceforge.net/xmlns/l10n/1.0"
		xmlns:h="http://www.w3.org/1999/xhtml"
		xmlns="http://www.w3.org/1999/xhtml"
		exclude-result-prefixes="l">

  <!-- Master template that should be called directly to do tocgen, indexgen, and xrefgen as specified via params -->

  <!-- Imports common.xsl for common utility templates --> 
  <xsl:import href="common.xsl"/>

  <xsl:include href="param.xsl"/> <!-- HTMLBook params -->
  <xsl:include href="idgen.xsl"/> <!-- Id decoration as needed for autogeneration of TOC/index -->
  <xsl:include href="tocgen.xsl"/> <!-- Autogeneration of TOC if specified in autogenerate-toc -->
  <xsl:include href="indexgen.xsl"/> <!-- Autogeneration of index if specified in autogenerate-index -->

  <xsl:output method="xml"
              encoding="UTF-8"/>
  <xsl:preserve-space elements="*"/>

  <xsl:template match="/">
    <!-- Autogeneration checks to throw relevant messages before processing the book:-->

    <!-- Was autogeneration of TOC specified, and is that possible? -->
    <xsl:choose>
      <xsl:when test="$autogenerate-toc = 1 and count(//h:nav[@class='toc']) = 0">
	<xsl:message>Unable to autogenerate TOC: no TOC "nav" element found.</xsl:message>
      </xsl:when>
      <xsl:when test="$autogenerate-toc = 1 and $toc-placeholder-overwrite-contents != 1 and count(//h:nav[@class='toc'][1][not(node())]) = 0">
	<xsl:message>Unable to autogenerate TOC: first TOC "nav" is not empty, and $toc-placeholder-overwrite-contents param not enabled.</xsl:message>
      </xsl:when>
    </xsl:choose>
    <!-- Was autogeneration of Index specified, and is that possible? -->
    <xsl:choose>
      <xsl:when test="$autogenerate-index = 1 and count(//h:section[@class='index']) = 0">
	<xsl:message>Unable to autogenerate Index: no Index "section" element found.</xsl:message>
      </xsl:when>
      <xsl:when test="$autogenerate-index = 1 and $index-placeholder-overwrite-contents != 1 and count(//h:section[@class='index'][1][not(node())]) = 0">
	<xsl:message>Unable to autogenerate Index: first Index "section" is not empty, and $index-placeholder-overwrite-contents param not enabled.</xsl:message>
      </xsl:when>
    </xsl:choose>

    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>

</xsl:stylesheet> 
