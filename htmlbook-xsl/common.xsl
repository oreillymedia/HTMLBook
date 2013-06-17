<xsl:stylesheet version="1.0"
		xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns:exsl="http://exslt.org/common"
		xmlns:l="http://docbook.sourceforge.net/xmlns/l10n/1.0"
		xmlns:h="http://www.w3.org/1999/xhtml"
		xmlns="http://www.w3.org/1999/xhtml"
		extension-element-prefixes="exsl"
		exclude-result-prefixes="exsl">
  <xsl:output method="xml"
              encoding="UTF-8"/>
  <xsl:preserve-space elements="*"/>

  <!-- ToDo: Make href.target more robust to deal with situations when stuff is chunked into different files -->

  <!-- Separator to be used between label and title -->
  <xsl:param name="label.and.title.separator" select="'. '"/>

  <!-- Separator to be used between parts of a label -->
  <xsl:param name="intralabel.separator" select="'.'"/>

  <!-- Default Rule; when no other templates are specified, copy direct to output -->
  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>

<!-- For any book division that you want to have numeration, specify the @class, followed by colon, 
     and then a valid @format value for <xsl:number/>. If there is no entry in this list, or "none" is specified, corresponding division
     will not get labeled -->
  <xsl:param name="label.numeration.by.class">
appendix:A
chapter:1
part:I
sect1:none
sect2:none
sect3:none
sect4:none
sect5:none
  </xsl:param>

  <!-- When labeling sections, also label their ancestors, e.g., 3.1 -->
  <xsl:param name="label.section.and.ancestors"/>

  <!-- Stylesheet for utility templates common to other stylesheets -->

  <!-- Generate target @href value pointing to given node -->
  <!-- Borrowed and adapted from xhtml/html.xsl in docbook-xsl stylesheets -->
  <xsl:template name="href.target">
    <xsl:param name="context" select="."/>
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

  <!-- Label handling -->
  <xsl:template match="*" mode="label.value">
    <xsl:call-template name="get-label-from-class">
      <xsl:with-param name="class" select="@class"/>
    </xsl:call-template>
  </xsl:template>

  <xsl:template name="get-label-from-class">
    <xsl:param name="class"/>
    <xsl:param name="numeration-format"/>

    <!-- Calculate numeration format -->
    <xsl:variable name="calculated-numeration-format">
      <xsl:choose>
	<xsl:when test="$numeration-format != ''">
	  <xsl:value-of select="$numeration-format"/>
	</xsl:when>
	<xsl:otherwise>
	  <xsl:variable name="label-numeration-excerpt-for-class">
	    <!-- Gets the config line for numeration for the specified class...and everything beyond -->
	    <xsl:value-of select="substring-after(normalize-space($label.numeration.by.class), concat($class, ':'))"/>
	  </xsl:variable>
	  <!-- Then we further narrow to the exact numeration format type -->
	  <xsl:choose>
	    <xsl:when test="contains($label-numeration-excerpt-for-class, ' ')">
	      <xsl:value-of select="substring-before($label-numeration-excerpt-for-class, ' ')"/>
	    </xsl:when>
	    <xsl:otherwise>
	      <xsl:value-of select="$label-numeration-excerpt-for-class"/>
	    </xsl:otherwise>
	  </xsl:choose>
	</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <!-- Now generate number using format -->
    <!-- ToDo: logic for section labeling with parent-element number in label (e.g., 1.8) -->
    <xsl:choose>
      <!-- I wish XSL allowed variables in @format attribute -->
      <xsl:when test="$calculated-numeration-format = '1'">
	<xsl:number count="*[@class = $class]" format="1"/>
	<xsl:value-of select="$label.and.title.separator"/>
      </xsl:when>
      <xsl:when test="$calculated-numeration-format = '01'">
	<xsl:number count="*[@class = $class]" format="01"/>
	<xsl:value-of select="$label.and.title.separator"/>
      </xsl:when>
      <xsl:when test="$calculated-numeration-format = 'a'">
	<xsl:number count="*[@class = $class]" format="a"/>
	<xsl:value-of select="$label.and.title.separator"/>
      </xsl:when>
      <xsl:when test="$calculated-numeration-format = 'A'">
	<xsl:number count="*[@class = $class]" format="A"/>
	<xsl:value-of select="$label.and.title.separator"/>
      </xsl:when>
      <xsl:when test="$calculated-numeration-format = 'i'">
	<xsl:number count="*[@class = $class]" format="i"/>
	<xsl:value-of select="$label.and.title.separator"/>
      </xsl:when>
      <xsl:when test="$calculated-numeration-format = 'I'">
	<xsl:number count="*[@class = $class]" format="I"/>
	<xsl:value-of select="$label.and.title.separator"/>
      </xsl:when>
      <xsl:when test="$calculated-numeration-format = 'none'"/>
      <xsl:otherwise>
	<!-- If $calculated-numeration-format doesn't match above values or is blank, no label can be generated -->
	<xsl:choose>
	  <xsl:when test="normalize-space($calculated-numeration-format) = ''">
	    <xsl:message>No label numeration format specified for <xsl:value-of select="$class"/>: skipping label</xsl:message>
	  </xsl:when>
	  <xsl:otherwise>
	    <xsl:message>Unable to generate label for <xsl:value-of select="$class"/> with numeration format <xsl:value-of select="$calculated-numeration-format"/>.</xsl:message>
	  </xsl:otherwise>
	</xsl:choose>
      </xsl:otherwise>
    </xsl:choose>    	
  </xsl:template>

  <!-- Logic for generating titles; default handling is to grab the first <h1>-<h6> content -->
  <xsl:template match="*" mode="titlegen">
    <xsl:choose>
      <xsl:when test="self::h:section[@class='index' and not(h:h1|h:h2|h:h3|h:h4|h:h5|h:h6)]">
	<xsl:call-template name="get-localization-value">
	  <xsl:with-param name="gentext-key" select="'index'"/>
	</xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
	<xsl:apply-templates select="(h:h1|h:h2|h:h3|h:h4|h:h5|h:h6)[1]//node()"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Get localization value for a language using localizations in $localizations -->
  <xsl:template name="get-localization-value">
    <xsl:param name="gentext-key"/>
    <xsl:param name="context"/>
    <!-- Find value within specific context, if specified -->
    <xsl:variable name="localizations-nodes" select="exsl:node-set($localizations)"/>
    <xsl:choose>
      <xsl:when test="$context != ''">
	<xsl:value-of select="$localizations-nodes//l:l10n/l:context[@name=$context]/l:template[@name = $gentext-key]/@text"/>
      </xsl:when>
      <xsl:otherwise>
	<xsl:value-of select="$localizations-nodes//l:l10n/l:gentext[@key = $gentext-key]/@text"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet> 
