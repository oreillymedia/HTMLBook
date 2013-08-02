<xsl:stylesheet version="1.0"
		xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns:h="http://www.w3.org/1999/xhtml"
		xmlns="http://www.w3.org/1999/xhtml"
		exclude-result-prefixes="h">

<!-- Template for id decoration on elements that need it for TOC and/or index generation. 
     Should be at a lower import level than tocgen.xsl and indexgen.xsl, so that those
     templates can override id-generation templates to add additional functionality, if needed -->

  <xsl:output method="xml"
              encoding="UTF-8"/>
  <xsl:preserve-space elements="*"/>

  <!-- Elements that require ids: 
       * All <sections>
       * <div data-type="part">
       * All <a data-type="indexterm"> tags
    -->
  <!-- WARNING: If you need additional handling for these elements for other functionality,
       and you override this template elsewhere, make sure you add in id-decoration functionality -->
  <xsl:template match="h:section|h:div[contains(@data-type, 'part')]|h:a[contains(@data-type, 'indexterm')]">
    <xsl:variable name="output-element-name">
      <xsl:call-template name="html.output.element"/>
    </xsl:variable>
    <xsl:element name="{$output-element-name}" namespace="http://www.w3.org/1999/xhtml">
      <xsl:apply-templates select="@*[not(local-name() = 'id')]"/>
      <xsl:attribute name="id">
	<xsl:call-template name="object.id"/>
      </xsl:attribute>
      <xsl:apply-templates/>      
    </xsl:element>
  </xsl:template>

  <xsl:template match="h:section/*[self::h:h1 or self::h:h2 or self::h:h3 or self::h:h4 or self::h:h5 or self::h:h6]|
		       h:div[@data-type = 'part' or @data-type = 'example']/*[self::h:h1 or self::h:h2 or self::h:h3 or self::h:h4 or self::h:h5 or self::h:h6]|
		       h:caption">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:if test="$autogenerate.labels = 1">
	<xsl:variable name="heading.label">
	  <xsl:apply-templates select=".." mode="label.markup"/>
	</xsl:variable>
	<xsl:if test="$heading.label != ''">
	  <span class="label">
	    <xsl:value-of select="$heading.label"/>
	    <xsl:value-of select="$label.and.title.separator"/>
	  </span>
	</xsl:if>
      </xsl:if>
      <xsl:apply-templates/>
    </xsl:copy>	
  </xsl:template>

  <xsl:template match="h:figure">
    <xsl:variable name="output-element-name">
      <xsl:call-template name="html.output.element"/>
    </xsl:variable>
    <xsl:element name="{$output-element-name}" namespace="http://www.w3.org/1999/xhtml">
      <xsl:apply-templates select="@*"/>
      <!-- If there's no data-type already and $html4.structural.elements is enabled, plop in a data type of "figure" -->
      <xsl:if test="not(@data-type) and $html4.structural.elements = 1">
	<xsl:attribute name="data-type">figure</xsl:attribute>
      </xsl:if>
      <xsl:apply-templates/>      
    </xsl:element>
  </xsl:template>

  <xsl:template match="h:figcaption">
    <xsl:variable name="output-element-name">
      <xsl:call-template name="html.output.element"/>
    </xsl:variable>
    <xsl:element name="{$output-element-name}" namespace="http://www.w3.org/1999/xhtml">
      <xsl:apply-templates select="@*"/>
      <xsl:if test="$autogenerate.labels = 1">
	<xsl:variable name="figure.label">
	  <xsl:apply-templates select=".." mode="label.markup"/>
	</xsl:variable>
	<xsl:if test="$figure.label != ''">
	  <span class="label">
	    <xsl:value-of select="$figure.label"/>
	    <xsl:value-of select="$label.and.title.separator"/>
	  </span>
	</xsl:if>
      </xsl:if>
      <xsl:apply-templates/>
    </xsl:element>
  </xsl:template>
</xsl:stylesheet> 
