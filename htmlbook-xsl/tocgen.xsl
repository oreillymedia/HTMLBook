<xsl:stylesheet version="1.0"
		xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns:func="http://exslt.org/functions"
		xmlns:h="http://www.w3.org/1999/xhtml"
		xmlns:htmlbook="https://github.com/oreillymedia/HTMLBook"
		xmlns="http://www.w3.org/1999/xhtml"
		extension-element-prefixes="func"
		exclude-result-prefixes="h func">

  <xsl:output method="xml"
              encoding="UTF-8"/>
  <xsl:preserve-space elements="*"/>

  <!-- Default rule for TOC generation -->
  <xsl:template match="*" mode="tocgen">
    <xsl:param name="toc.section.depth" select="$toc.section.depth"/>
    <xsl:apply-templates select="*" mode="tocgen"/>
  </xsl:template>

  <xsl:template match="h:section[not(@data-type = 'dedication' or @data-type = 'titlepage' or @data-type = 'toc' or @data-type = 'colophon' or @data-type = 'copyright-page' or @data-type = 'halftitlepage')]|h:div[@data-type='part']" mode="tocgen">
    <xsl:param name="toc.section.depth" select="$toc.section.depth"/>
    <xsl:choose>
      <!-- Don't output entry for section elements at a level that is greater than specified $toc.section.depth -->
      <xsl:when test="self::h:section[contains(@data-type, 'sect') and htmlbook:section-depth(.) != '' and htmlbook:section-depth(.) &gt; $toc.section.depth]"/>
      <!-- Otherwise, go ahead -->
      <xsl:otherwise>
	<xsl:element name="li">
	  <xsl:attribute name="data-type">
	    <xsl:value-of select="@data-type"/>
	  </xsl:attribute>
	  <a>
	    <xsl:attribute name="href">
	      <xsl:call-template name="href.target">
		<xsl:with-param name="object" select="."/>
	      </xsl:call-template>
	    </xsl:attribute>
	    <xsl:if test="$toc-include-labels = 1">
	      <xsl:variable name="toc-entry-label">
		<xsl:apply-templates select="." mode="label.markup"/>
	      </xsl:variable>
	      <xsl:value-of select="normalize-space($toc-entry-label)"/>
	      <xsl:if test="$toc-entry-label != ''">
		<xsl:value-of select="$label.and.title.separator"/>
	      </xsl:if>
	    </xsl:if>
	    <xsl:apply-templates select="." mode="title.markup"/>
	  </a>
	  <!-- Make sure there are descendants that conform to $toc.section.depth restrictions before generating nested TOC <ol> -->
	  <xsl:if test="descendant::h:section[not(contains(@data-type, 'sect')) or htmlbook:section-depth(.) &lt;= $toc.section.depth]|descendant::h:div[@data-type='part']">
	    <ol>
	      <xsl:apply-templates mode="tocgen"/>
	    </ol>
	  </xsl:if>
	</xsl:element>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="h:nav[@data-type='toc']" name="generate-toc">
    <xsl:param name="toc.node" select="."/>
    <xsl:param name="scope" select="/*"/>
    <xsl:param name="autogenerate-toc" select="$autogenerate-toc"/>
    <xsl:param name="toc-placeholder-overwrite-contents" select="$toc-placeholder-overwrite-contents"/>

    <!-- Just switch context to $toc.node, so we don't have to reference the variable in rest of template -->
    <xsl:for-each select="$toc.node">
      <xsl:choose>
	<!-- If autogenerate-toc is enabled, and it's the first toc-placeholder-element, and it's either empty or overwrite-contents is specified, then
	     go ahead and generate the TOC here -->
	<xsl:when test="($autogenerate-toc = 1) and
			(not(node()) or $toc-placeholder-overwrite-contents != 0)">
	  <xsl:copy>
	    <xsl:apply-templates select="@*[not(local-name() = 'id')]"/>
	    <xsl:attribute name="id">
	      <xsl:call-template name="object.id"/>
	    </xsl:attribute>
	    <xsl:if test="$toc-include-title != 0">
	      <h1>
		<xsl:call-template name="toc-title"/>
	      </h1>
	    </xsl:if>
	    <ol>
	      <xsl:apply-templates select="$scope" mode="tocgen"/>
	    </ol>
	  </xsl:copy>
	</xsl:when>
	<xsl:otherwise>
	  <!-- Otherwise, just process as normal -->
	  <xsl:copy>
	    <xsl:apply-templates select="@*[not(local-name() = 'id')]"/>
	    <xsl:attribute name="id">
	      <xsl:call-template name="object.id"/>
	    </xsl:attribute>
	    <xsl:apply-templates/>
	  </xsl:copy>
	</xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="toc-title">
    <!-- Override if you want a different value for the title heading on the TOC (e.g., the book title) -->
    <xsl:call-template name="get-localization-value">
      <xsl:with-param name="gentext-key" select="'tableofcontents'"/>
    </xsl:call-template>
  </xsl:template>

</xsl:stylesheet> 
