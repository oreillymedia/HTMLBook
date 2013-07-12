<xsl:stylesheet version="1.0"
		xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns:dc="http://purl.org/dc/elements/1.1/"
		xmlns:ncx="http://www.daisy.org/z3986/2005/ncx/"
		xmlns:dcterms="http://purl.org/dc/terms/"
		xmlns:opf="http://www.idpf.org/2007/opf"
		xmlns:m="http://www.w3.org/1998/Math/MathML"
		xmlns:svg="http://www.w3.org/2000/svg"
		xmlns:date="http://exslt.org/dates-and-times"
		xmlns:exsl="http://exslt.org/common"
		xmlns:set="http://exslt.org/sets"
		xmlns:e="http://github.com/oreillymedia/epubrenderer"
		xmlns:h="http://www.w3.org/1999/xhtml"
		xmlns:htmlbook="https://github.com/oreillymedia/HTMLBook"
		xmlns:func="http://exslt.org/functions"
		xmlns="http://www.daisy.org/z3986/2005/ncx/"
		extension-element-prefixes="exsl func set date"
		exclude-result-prefixes="date e exsl func h htmlbook m ncx opf set svg">

  <!-- ToDo: Section depth handling for NCX navPoints -->
  <!-- ToDo: playOrder attrs -->

  <!-- Param to specify whether or not to include the Navigation Document (XHTML5 TOC) in the NCX TOC -->
  <xsl:variable name="nav.in.ncx" select="0"/>

  <!-- Generate an NCX file from HTMLBook source. -->
  <xsl:template name="generate.ncx.toc">
    <xsl:variable name="full-ncx-filename">
      <xsl:call-template name="full-output-filename">
	<xsl:with-param name="output-filename" select="$ncx.toc.filename"/>
      </xsl:call-template>
    </xsl:variable>
    <exsl:document href="{$full-ncx-filename}" method="xml" encoding="UTF-8">
      <ncx version="2005-1">
	<head>
	  <xsl:if test="$generate.cover.html = 1">
	    <meta name="cover" content="{$epub.cover.html.id}"/>
	  </xsl:if>
	  <meta name="dtb:uid" content="{$metadata.unique-identifier}"/>
	</head>
	<docTitle>
	  <text>
	    <xsl:value-of select="$metadata.title"/>
	  </text>
	</docTitle>
	<navMap>
	  <xsl:apply-templates select="/*" mode="ncx.toc.gen"/>
	</navMap>
      </ncx>
    </exsl:document>
  </xsl:template>

  <!-- Default rule for TOC generation -->
  <xsl:template match="*" mode="ncx.toc.gen">
    <xsl:apply-templates select="*" mode="ncx.toc.gen"/>
  </xsl:template>

  <xsl:template match="h:section[not(@data-type = 'dedication' or @data-type = 'titlepage' or @data-type = 'toc' or @data-type = 'colophon' or @data-type = 'copyright-page' or @data-type = 'halftitlepage')]|h:div[@data-type='part']|h:nav[@data-type='toc']" mode="ncx.toc.gen">
    <!-- Exclude nav elements from NCX if $nav.in.ncx != 1 -->
    <xsl:for-each select="self::*[not(self::h:nav[$nav.in.ncx != 1])]">
      <navPoint>
	<xsl:attribute name="id">
	  <!-- Use OPF ids in NCX as well -->
	  <xsl:apply-templates select="." mode="opf.id"/>
	</xsl:attribute>
	<navLabel>
	  <xsl:if test="$ncx.toc.include.labels = 1">
	    <xsl:variable name="toc-entry-label">
	      <xsl:apply-templates select="." mode="label.markup"/>
	    </xsl:variable>
	    <xsl:value-of select="normalize-space($toc-entry-label)"/>
	    <xsl:if test="$toc-entry-label != ''">
	      <xsl:value-of select="$label.and.title.separator"/>
	    </xsl:if>
	  </xsl:if>
	  <xsl:apply-templates select="." mode="title.markup"/>
	</navLabel>
	<content>
	  <xsl:attribute name="src">
	    <xsl:call-template name="href.target">
	      <xsl:with-param name="object" select="."/>
	    </xsl:call-template>
	  </xsl:attribute>
	</content>
	<xsl:apply-templates select="*" mode="ncx.toc.gen"/>
      </navPoint>
    </xsl:for-each>
  </xsl:template>

</xsl:stylesheet> 
