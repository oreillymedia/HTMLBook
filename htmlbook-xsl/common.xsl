<xsl:stylesheet version="1.0"
		xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns:h="http://www.w3.org/1999/xhtml"
		xmlns="http://www.w3.org/1999/xhtml">
  <xsl:output method="xml"
              encoding="UTF-8"/>
  <xsl:preserve-space elements="*"/>

  <!-- Stylesheet for utility templates common to other stylesheets -->

  <!-- Generate target @href value pointing to given node -->
  <!-- Borrowed and adapted from xhtml/html.xsl in docbook-xsl stylesheets -->
  <xsl:template name="href.target">
    <xsl:param name="object" select="."/>
    <xsl:text>#</xsl:text>
    <xsl:call-template name="object.id">
      <xsl:with-param name="object" select="$object"/>
    </xsl:call-template>
  </xsl:template>

  <!-- Generate an id from a node -->
  <!-- Borrowed and adapted from common/common.xsl in the docbook-xsl stylesheets -->
  <xsl:template name="object.id">
    <xsl:param name="object" select="."/>
    <xsl:choose>
      <xsl:when test="$object/@id">
	<xsl:value-of select="$object/@id"/>
      </xsl:when>
      <xsl:when test="$object/@xml:id">
	<xsl:value-of select="$object/@xml:id"/>
      </xsl:when>
      <xsl:otherwise>
	<xsl:value-of select="generate-id($object)"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet> 
