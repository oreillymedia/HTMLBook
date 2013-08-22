<xsl:stylesheet version="1.0"
		xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:l="http://docbook.sourceforge.net/xmlns/l10n/1.0"
		xmlns:h="http://www.w3.org/1999/xhtml"
		xmlns="http://www.w3.org/1999/xhtml"
		exclude-result-prefixes="l">

  <!-- Global ToDo: switch logic from @data-type = whatever to contains(@data-type, 'whatever')? Depends on how much flexibility we want to allow in @data-type values in different contexts -->

  <!-- Master template that should be called directly to do tocgen, indexgen, and xrefgen as specified via params -->

  <!-- Imports common.xsl for common utility templates --> 
  <xsl:import href="common.xsl"/>

  <xsl:include href="param.xsl"/> <!-- HTMLBook params -->
  <xsl:include href="elements.xsl"/> <!-- Postprocessing of elements as needed (e.g., Id decoration as needed for autogeneration of TOC/index) -->
  <xsl:include href="tocgen.xsl"/> <!-- Autogeneration of TOC if specified in autogenerate-toc -->
  <xsl:include href="indexgen.xsl"/> <!-- Autogeneration of index if specified in autogenerate-index -->
  <xsl:include href="xrefgen.xsl"/> <!-- Autogeneration of XREFs if specified in autogenerate-xrefs -->

  <xsl:output method="xml"
              encoding="UTF-8"/>
  <xsl:preserve-space elements="*"/>

  <xsl:template match="/">
    <!-- Autogeneration checks to throw relevant messages before processing the book:-->

    <!-- Was autogeneration of TOC specified, and is that possible? -->
    <xsl:choose>
      <xsl:when test="$autogenerate-toc = 1 and count(//h:nav[@data-type='toc']) = 0">
	<xsl:call-template name="log-message">
	  <xsl:with-param name="type" select="'WARNING'"/>
	  <xsl:with-param name="message">
	    <xsl:text>WARNING: Unable to autogenerate TOC: no TOC "nav" element found.</xsl:text>
	  </xsl:with-param>
	</xsl:call-template>
      </xsl:when>
      <xsl:when test="$autogenerate-toc = 1 and $toc-placeholder-overwrite-contents != 1 and count(//h:nav[@data-type='toc'][1][not(node())]) = 0">
	<xsl:call-template name="log-message">
	  <xsl:with-param name="type" select="'WARNING'"/>
	  <xsl:with-param name="message">
	    <xsl:text>Unable to autogenerate TOC: first TOC "nav" is not empty, and $toc-placeholder-overwrite-contents param not enabled.</xsl:text>
	  </xsl:with-param>
	</xsl:call-template>
      </xsl:when>
    </xsl:choose>
    <!-- Was autogeneration of Index specified, and is that possible? -->
    <xsl:choose>
      <xsl:when test="$autogenerate-index = 1 and count(//h:section[@data-type='index']) = 0">
	<xsl:call-template name="log-message">
	  <xsl:with-param name="type" select="'WARNING'"/>
	  <xsl:with-param name="message">
	    <xsl:text>Unable to autogenerate Index: no Index "section" element found.</xsl:text>
	  </xsl:with-param>
	</xsl:call-template>
      </xsl:when>
      <xsl:when test="$autogenerate-index = 1 and $index-placeholder-overwrite-contents != 1 and count(//h:section[@data-type='index'][1][not(node())]) = 0">
	<xsl:call-template name="log-message">
	  <xsl:with-param name="type" select="'WARNING'"/>
	  <xsl:with-param name="message">
	    <xsl:text>Unable to autogenerate Index: first Index "section" is not empty, and $index-placeholder-overwrite-contents param not enabled.</xsl:text>
	  </xsl:with-param>
	</xsl:call-template>
      </xsl:when>
    </xsl:choose>

    <!-- Was autogeneration of XREFs specified, and are there any XREFs with existing text content that would or would not be overwritten? -->
    <xsl:if test="$autogenerate-xrefs = 1 and count(//h:a[@data-type='xref'][. != '']) > 0">
      <!-- If autogeneration of XREFs was specified and overwriting of existing XREF content *was not* specified,
	   report all XREFs that will not be overwritten -->
      <xsl:call-template name="log-message">
	<xsl:with-param name="type" select="'WARNING'"/>
	<xsl:with-param name="message">
	  <xsl:choose>
	    <xsl:when test="$xref-placeholder-overwrite-contents != 1">
	      <xsl:text>Warning: the following XREFs already have content in their text nodes, which will not be overwritten (rerun stylesheets with $xref-placeholder-overwrite-contents = 1 if you want to overwrite):</xsl:text>
	    </xsl:when>
	    <xsl:otherwise>
	      <xsl:text>Warning: the following XREFs already have content in their text nodes, which will be overwritten (rerun stylesheets with $xref-placeholder-overwrite-contents = 0 if you don't want to overwrite):</xsl:text>
	    </xsl:otherwise>
	  </xsl:choose>
	  <xsl:for-each select="//h:a[@data-type='xref'][. != '']">
	    XREF text: <xsl:value-of select="normalize-space(.)"/>; XREF target: <xsl:value-of select="@href"/>
	  </xsl:for-each>
	</xsl:with-param>
      </xsl:call-template>
    </xsl:if>

    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>

</xsl:stylesheet> 
