<xsl:stylesheet version="1.0"
		xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:l="http://docbook.sourceforge.net/xmlns/l10n/1.0"
		xmlns:h="http://www.w3.org/1999/xhtml"
		xmlns="http://www.w3.org/1999/xhtml"
		exclude-result-prefixes="l">

  <!-- Global ToDo: switch logic from @class = whatever to contains(@class, 'whatever') -->

  <!-- Chunk template used to split content among multiple .html files -->

  <!-- Imports htmlbook.xsl -->
  <xsl:import href="htmlbook.xsl"/>

  <xsl:output method="xml"
              encoding="UTF-8"/>
  <xsl:preserve-space elements="*"/>

  <!-- Specify a number from 0 to 5, where 0 means chunk at top-level sections (part, chapter, appendix), and 1-5 means chunk at the corresponding sect level (sect1 - sect5) -->
  <xsl:param name="chunk.level" select="0"/>

  <xsl:template match="h:section|h:div[contains(@class, 'part')]|h:nav">
    <xsl:variable name="is.chunk">
      <xsl:call-template name="is-chunk"/>
    </xsl:variable>
    <xsl:message>Element name: <xsl:value-of select="local-name()"/>, Class name: <xsl:value-of select="@class"/>, Is chunk: <xsl:value-of select="$is.chunk"/></xsl:message>
    <xsl:apply-imports/>
  </xsl:template>

  <xsl:template name="is-chunk">
    <xsl:param name="node" select="."/>
    <xsl:choose>
      <xsl:when test="self::h:div[contains(@class, 'part')]">
	<xsl:text>1</xsl:text>
      </xsl:when>
      <xsl:when test="self::h:section[contains(@class, 'acknowledgments') or
		      contains(@class, 'afterword') or
		      contains(@class, 'appendix') or
		      contains(@class, 'bibliography') or
		      contains(@class, 'chapter') or
		      contains(@class, 'colophon') or
		      contains(@class, 'conclusion') or
		      contains(@class, 'copyright-page') or
		      contains(@class, 'dedication') or
		      contains(@class, 'foreword') or
		      contains(@class, 'glossary') or
		      contains(@class, 'halftitlepage') or
		      contains(@class, 'index') or
		      contains(@class, 'introduction') or
		      contains(@class, 'preface') or
		      contains(@class, 'titlepage') or
		      contains(@class, 'toc')]">
	<xsl:text>1</xsl:text>
      </xsl:when>
      <xsl:when test="self::h:nav[contains(@class, 'toc')]">
	<xsl:text>1</xsl:text>
      </xsl:when>
      <xsl:when test="self::h:section[contains(@class, 'sect')]">
	<xsl:variable name="sect-level">
	  <xsl:value-of select="substring(substring-after(@class, 'sect'), 1, 1)"/>
	</xsl:variable>
	<xsl:if test="($sect-level = '1' or $sect-level = '2' or $sect-level = '3' or $sect-level = '4' or $sect-level = '5') and
		      $sect-level &lt;= $chunk.level">
	  <xsl:text>1</xsl:text>
	</xsl:if>	
      </xsl:when>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet> 
