<xsl:stylesheet version="1.0"
		xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns:ncx="http://www.daisy.org/z3986/2005/ncx/"
		xmlns:exsl="http://exslt.org/common"
		xmlns:h="http://www.w3.org/1999/xhtml"
		xmlns:htmlbook="https://github.com/oreillymedia/HTMLBook"
		xmlns:func="http://exslt.org/functions"
		xmlns="http://www.daisy.org/z3986/2005/ncx/"
		extension-element-prefixes="exsl func"
		exclude-result-prefixes="exsl func h htmlbook ncx">

  <!-- ToDo: Section depth handling for NCX navPoints -->

  <!-- Param to specify whether or not to include the Navigation Document (XHTML5 TOC) in the NCX TOC -->
  <xsl:variable name="nav.in.ncx" select="0"/>

  <xsl:variable name="full.ncx.filename">
    <xsl:value-of select="$outputdir"/>
    <xsl:if test="substring($outputdir, string-length($outputdir), 1) != '/'">
      <xsl:text>/</xsl:text>
    </xsl:if>
    <xsl:value-of select="$ncx.toc.filename"/>
  </xsl:variable>

  <!-- Generate an NCX file from HTMLBook source. -->
  <xsl:template name="generate.ncx.toc">
    <exsl:document href="{$full.ncx.filename}" method="xml" encoding="UTF-8">
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
	<xsl:variable name="navMap">
	  <navMap>
	    <!-- Only put root chunk in the NCX TOC if $ncx.include.root.chunk is enabled -->
	    <xsl:if test="$ncx.include.root.chunk = 1">
	      <navPoint>
		<xsl:attribute name="id">
		  <!-- Use OPF ids in NCX as well -->
		  <xsl:apply-templates select="/*" mode="opf.id"/>
		</xsl:attribute>
		<navLabel>
		  <text>
		    <!-- Look for title first in head, then as child of body -->
		    <xsl:value-of select="(//h:head/h:title|//h:body/h:h1)[1]"/>
		  </text>
		</navLabel>
	      <content src="{$root.chunk.filename}"/>
	      </navPoint>
	    </xsl:if>
	    <xsl:apply-templates select="/*" mode="ncx.toc.gen"/>
	  </navMap>
	</xsl:variable>
	<xsl:apply-templates select="exsl:node-set($navMap)" mode="output.navMap.with.playOrder"/>
      </ncx>
    </exsl:document>
  </xsl:template>

  <!-- Default rule for TOC generation -->
  <xsl:template match="*" mode="ncx.toc.gen">
    <xsl:apply-templates select="*" mode="ncx.toc.gen"/>
  </xsl:template>

  <xsl:template match="h:section[not(@data-type = 'dedication' or @data-type = 'titlepage' or @data-type = 'toc' or @data-type = 'colophon' or @data-type = 'copyright-page' or @data-type = 'halftitlepage')]|h:div[@data-type='part']" mode="ncx.toc.gen">
    <xsl:call-template name="generate.navpoint"/>
  </xsl:template>

  <!-- Only put the Nav doc in the NCX TOC if $nav.in.ncx is enabled -->
  <xsl:template match="h:nav[@data-type='toc']" mode="ncx.toc.gen">
    <xsl:if test="$nav.in.ncx = 1">
      <xsl:call-template name="generate.navpoint"/>
    </xsl:if>
  </xsl:template>

  <xsl:template match="@*|node()" mode="output.navMap.with.playOrder">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()" mode="output.navMap.with.playOrder"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="ncx:navPoint" mode="output.navMap.with.playOrder">
    <xsl:copy>
      <xsl:apply-templates select="@*" mode="output.navMap.with.playOrder"/>
      <xsl:attribute name="playOrder">
	<xsl:number count="ncx:navPoint" level="any"/>
      </xsl:attribute>
      <xsl:apply-templates select="*" mode="output.navMap.with.playOrder"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template name="generate.navpoint">
    <xsl:param name="node" select="."/>
    <!-- Traverse down the tree and process descendant navpoints? Default is "yes" -->
    <xsl:param name="process-descendants" select="1"/>
    <navPoint>
      <xsl:attribute name="id">
	<!-- Use OPF ids in NCX as well -->
	<xsl:apply-templates select="$node" mode="opf.id"/>
      </xsl:attribute>
      <navLabel>
	<text>
	  <xsl:if test="$ncx.toc.include.labels = 1">
	    <xsl:variable name="toc-entry-label">
	      <xsl:apply-templates select="$node" mode="label.markup"/>
	    </xsl:variable>
	    <xsl:value-of select="normalize-space($toc-entry-label)"/>
	    <xsl:if test="$toc-entry-label != ''">
	      <xsl:value-of select="$label.and.title.separator"/>
	    </xsl:if>
	  </xsl:if>
	  <xsl:apply-templates select="$node" mode="title.markup"/>
	</text>
      </navLabel>
      <content>
	<xsl:attribute name="src">
	  <xsl:call-template name="href.target">
	    <xsl:with-param name="object" select="$node"/>
	  </xsl:call-template>
	</xsl:attribute>
      </content>
      <xsl:if test="$process-descendants = 1">
	<xsl:apply-templates select="$node/*" mode="ncx.toc.gen"/>
      </xsl:if>
    </navPoint>
  </xsl:template>

</xsl:stylesheet> 
