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

  <!-- Specify a prefix for output filename for a given class -->
  <xsl:param name="output.filename.prefix.by.class">
appendix:app
chapter:ch
part:part
sect1:s
sect2:s
sect3:s
sect4:s
sect5:s
  </xsl:param>

  <xsl:template match="h:section|h:div[contains(@class, 'part')]|h:nav[contains(@class, 'toc')]">
    <xsl:variable name="is.chunk">
      <xsl:call-template name="is-chunk"/>
    </xsl:variable>
    <!-- <xsl:message>Element name: <xsl:value-of select="local-name()"/>, Class name: <xsl:value-of select="@class"/>, Is chunk: <xsl:value-of select="$is.chunk"/></xsl:message> -->
    <xsl:if test="$is.chunk = 1">
      <xsl:variable name="output-filename">
	<xsl:call-template name="output-filename-for-chunk"/>
      </xsl:variable>
      <!-- <xsl:message>Output filename: <xsl:value-of select="$output-filename"/></xsl:message> -->
    </xsl:if>
    <xsl:apply-imports/>
  </xsl:template>

  <xsl:template name="output-filename-for-chunk">
    <xsl:param name="node" select="."/>
    <xsl:param name="original-call" select="1"/>

    <xsl:variable name="node-name" select="local-name($node)"/>
    <xsl:variable name="node-class" select="$node/@class"/>

    <!-- Check to see if parent is also chunk, in which case, call template recursively -->
    <xsl:variable name="parent-node" select="$node/parent::*"/>
    <xsl:variable name="parent-is-chunk">
      <xsl:call-template name="is-chunk">
	<xsl:with-param name="node" select="$parent-node"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:if test="$parent-is-chunk = '1'">
      <xsl:call-template name="output-filename-for-chunk">
	<xsl:with-param name="node" select="$parent-node"/>
	<!-- Set $original-call to 0 for recursive calls of function -->
	<xsl:with-param name="original-call" select="0"/>
      </xsl:call-template>
    </xsl:if>
    <!-- We are assuming (in accordance with HTMLBook spec) that if an element is chunkable, it has a @class -->
    <xsl:variable name="filename-prefix-from-class">
      <xsl:call-template name="get-param-value-from-key">
	<xsl:with-param name="parameter" select="$output.filename.prefix.by.class"/>
	<xsl:with-param name="key" select="$node-class"/>
      </xsl:call-template>
    </xsl:variable>
    <!-- If prefix is specified in $filename-prefix-from-class, then use that -->
    <xsl:choose>
      <xsl:when test="$filename-prefix-from-class != ''">
	<xsl:value-of select="$filename-prefix-from-class"/>
      </xsl:when>
      <xsl:otherwise>
	<!-- Otherwise, fall back to class name -->
	<xsl:value-of select="$node-class"/>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:number count="*[local-name() = $node-name and @class = $node-class]" format="01"/>
    <xsl:if test="$original-call = 1">
      <!-- ToDo: Parameterize me to allow use of different filename extension? -->
      <xsl:text>.html</xsl:text>
    </xsl:if>
  </xsl:template>

  <xsl:template name="is-chunk">
    <xsl:param name="node" select="."/>
    <xsl:choose>
      <xsl:when test="$node[self::h:div[contains(@class, 'part')]]">
	<xsl:text>1</xsl:text>
      </xsl:when>
      <xsl:when test="$node[self::h:section[contains(@class, 'acknowledgments') or
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
		      contains(@class, 'toc')]]">
	<xsl:text>1</xsl:text>
      </xsl:when>
      <xsl:when test="$node[self::h:nav[contains(@class, 'toc')]]">
	<xsl:text>1</xsl:text>
      </xsl:when>
      <xsl:when test="$node[self::h:section[contains(@class, 'sect')]]">
	<xsl:variable name="sect-level">
	  <xsl:value-of select="substring(substring-after($node/@class, 'sect'), 1, 1)"/>
	</xsl:variable>
	<xsl:if test="($sect-level = '1' or $sect-level = '2' or $sect-level = '3' or $sect-level = '4' or $sect-level = '5') and
		      $sect-level &lt;= $chunk.level">
	  <xsl:text>1</xsl:text>
	</xsl:if>	
      </xsl:when>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet> 
