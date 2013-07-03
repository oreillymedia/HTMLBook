<xsl:stylesheet version="1.0"
		xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns:h="http://www.w3.org/1999/xhtml"
		xmlns="http://www.w3.org/1999/xhtml"
		exclude-result-prefixes="h">

<!-- Functionality still ToDo: Setting TOC section depth (e.g., how many levels of sections to include in TOC) -->

  <xsl:output method="xml"
              encoding="UTF-8"/>
  <xsl:preserve-space elements="*"/>

  <!-- Default rule for TOC generation -->
  <xsl:template match="*" mode="tocgen">
    <xsl:apply-templates select="*" mode="tocgen"/>
  </xsl:template>

  <xsl:template match="h:section[not(@data-type = 'dedication' or @data-type = 'titlepage' or @data-type = 'toc' or @data-type = 'colophon' or @data-type = 'copyright-page' or @data-type = 'halftitlepage')]|h:div[@data-type='part']" mode="tocgen">
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
	  <xsl:apply-templates select="." mode="label.markup"/>
	  <xsl:value-of select="$label.and.title.separator"/>
	</xsl:if>
	<xsl:apply-templates select="." mode="title.markup"/>
      </a>
      <xsl:if test="descendant::h:section|descendant::h:div[@data-type='part']">
	<ol>
	  <xsl:apply-templates mode="tocgen"/>
	</ol>
      </xsl:if>
    </xsl:element>
  </xsl:template>

  <xsl:template match="h:nav[@data-type='toc']">
    <xsl:choose>
      <!-- If autogenerate-toc is enabled, and it's the first toc-placeholder-element, and it's either empty or overwrite-contents is specified, then
	   go ahead and generate the TOC here -->
      <xsl:when test="($autogenerate-toc = 1) and 
		      (not(preceding::h:nav[@data-type='toc'])) and
		      (not(node()) or $toc-placeholder-overwrite-contents != 0)">
	<xsl:copy>
	  <xsl:apply-templates select="@*[not(local-name() = 'id')]"/>
	  <xsl:attribute name="id">
	    <xsl:call-template name="object.id"/>
	  </xsl:attribute>
	  <xsl:if test="$toc-include-title != 0">
	    <h1>
	      <xsl:value-of select="//h:body/h1"/>
	    </h1>
	  </xsl:if>
	  <ol>
	    <xsl:apply-templates select="/*" mode="tocgen"/>
	  </ol>
	</xsl:copy>
      </xsl:when>
      <xsl:otherwise>
	<!-- Otherwise, just process as normal -->
	<!-- ToDo: Consider using <xsl:apply-imports> here, depending on how we decide to do stylesheet layering for packaging for EPUB, etc. -->
	<xsl:copy>
	  <xsl:apply-templates select="@*[not(local-name() = 'id')]"/>
	  <xsl:attribute name="id">
	    <xsl:call-template name="object.id"/>
	  </xsl:attribute>
	  <xsl:apply-templates/>
	</xsl:copy>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet> 
