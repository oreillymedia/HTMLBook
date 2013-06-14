<xsl:stylesheet version="1.0"
		xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:l="http://docbook.sourceforge.net/xmlns/l10n/1.0"
		xmlns:h="http://www.w3.org/1999/xhtml"
		xmlns="http://www.w3.org/1999/xhtml"
		exclude-result-prefixes="l">

  <!-- Master template that should be called directly to do tocgen, indexgen, and xrefgen as specified via params -->

  <!-- Imports common.xsl for common utility templates --> 
  <xsl:import href="common.xsl"/>

  <xsl:include href="idgen.xsl"/> <!-- Id decoration as needed for autogeneration of TOC/index -->
  <xsl:include href="tocgen.xsl"/> <!-- Autogeneration of TOC if specified in autogenerate-toc -->
  <xsl:include href="indexgen.xsl"/> <!-- Autogeneration of index if specified in autogenerate-index -->

  <xsl:output method="xml"
              encoding="UTF-8"/>
  <xsl:preserve-space elements="*"/>

  <xsl:param name="autogenerate-toc" select="1"/>
  <xsl:param name="autogenerate-index" select="1"/>

  <xsl:param name="book-language">
    <xsl:choose>
      <xsl:when test="//h:html[@lang != '']|//h:body[@lang != '']">
	<xsl:value-of select="(//h:html[@lang != '']|//h:body[@lang != ''])[1]"/>
      </xsl:when>
      <xsl:otherwise>
	<xsl:text>en</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:param>

  <xsl:param name="localizations-dir" select="localizations/"/>

  <xsl:param name="localizations">
    <xsl:variable name="localizations-file">
      <xsl:value-of select="concat($localizations-dir, $book-language, '.xml')"/>
    </xsl:variable>
    <xsl:choose>
      <!-- If $localizations-file is valid, use it... -->
      <xsl:when test="document($localizations-file//l:l10n">
	<xsl:copy-of select="document($localizations-file)"/>
      </xsl:when>
      <!-- Otherwise default to "en" (English) -->
      <xsl:otherwise>
	<xsl:copy-of select="document($localizations-dir, 'en', '.xml')"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:param>

</xsl:stylesheet> 
