<xsl:stylesheet version="1.0"
		xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns:exsl="http://exslt.org/common"
		xmlns:l="http://docbook.sourceforge.net/xmlns/l10n/1.0"
		xmlns:h="http://www.w3.org/1999/xhtml"
		xmlns="http://www.w3.org/1999/xhtml"
		extension-element-prefixes="exsl"
		exclude-result-prefixes="exsl h">
  <xsl:output method="xml"
              encoding="UTF-8"/>
  <xsl:preserve-space elements="*"/>

  <!-- key for getting elements by id -->
  <xsl:key name="id" match="*" use="@id"/>

  <!-- ToDo: Make href.target more robust to deal with situations when stuff is chunked into different files -->

  <!-- Default Rule; when no other templates are specified, copy direct to output -->
  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>

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
  <xsl:template match="h:div[contains(@class, part)]|h:section" mode="label.markup">
    <xsl:call-template name="get-label-from-class">
      <xsl:with-param name="class" select="@class"/>
    </xsl:call-template>
  </xsl:template>

  <xsl:template match="h:table" mode="label.markup">
    <xsl:choose>
      <xsl:when test="$label.formal.with.ancestor != 0">
	<xsl:apply-templates select="ancestor::h:section[contains(@class, 'acknowledgments') or
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
				     contains(@class, 'toc')][last()]" mode="label.markup"/>
	<xsl:apply-templates select="." mode="intralabel.punctuation"/>
	<xsl:number count="h:table" from="h:section[contains(@class, 'acknowledgments') or
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
					  contains(@class, 'toc')" level="any" format="1"/>
      </xsl:when>
      <xsl:otherwise>
	<xsl:number count="h:table" level="any" format="1"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="h:figure" mode="label.markup">
    <xsl:choose>
      <xsl:when test="$label.formal.with.ancestor != 0">
	<xsl:apply-templates select="ancestor::h:section[contains(@class, 'acknowledgments') or
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
				     contains(@class, 'toc')][last()]" mode="label.markup"/>
	<xsl:apply-templates select="." mode="intralabel.punctuation"/>
	<xsl:number count="h:figure" from="h:section[contains(@class, 'acknowledgments') or
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
					   contains(@class, 'toc')" level="any" format="1"/>
      </xsl:when>
      <xsl:otherwise>
	<xsl:number count="h:figure" level="any" format="1"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="h:div[contains(@class, 'example')]" mode="label.markup">
    <xsl:choose>
      <xsl:when test="$label.formal.with.ancestor != 0">
	<xsl:apply-templates select="ancestor::h:section[contains(@class, 'acknowledgments') or
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
				     contains(@class, 'toc')][last()]" mode="label.markup"/>
	<xsl:apply-templates select="." mode="intralabel.punctuation"/>
	<xsl:number count="h:div[contains(@class, 'example')]" from="h:section[contains(@class, 'acknowledgments') or
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
								     contains(@class, 'toc')" level="any" format="1"/>
      </xsl:when>
      <xsl:otherwise>
	<xsl:number count="h:div[contains(@class, 'example')]" level="any" format="1"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="*" mode="label.markup"/>

  <!-- Intralabel punctuation templates.
       NOTE: These templates are based on the element being labeled (i.e., the last number in the label
    -->
  
  <xsl:template match="*" mode="intralabel.punctuation">
    <xsl:text>.</xsl:text>
  </xsl:template>

  <xsl:template match="h:figure|h:table|h:div[@class='example']" mode="intralabel.punctuation">
    <xsl:text>-</xsl:text>
  </xsl:template>

  <!-- Template that pulls a value from a key/value list in an <xsl:param> that looks like this: 
       key1:value1
       key2:value2
    -->
  <xsl:template name="get-param-value-from-key">
    <xsl:param name="parameter"/>
    <xsl:param name="key"/>
    <xsl:variable name="entry-and-beyond-for-class">
      <!-- Gets the config line for numeration for the specified class...and everything beyond -->
      <xsl:value-of select="substring-after(normalize-space($parameter), concat($key, ':'))"/>
    </xsl:variable>
    <!-- Then we further narrow to the exact numeration format type -->
    <xsl:choose>
      <xsl:when test="contains($entry-and-beyond-for-class, ' ')">
	<xsl:value-of select="substring-before($entry-and-beyond-for-class, ' ')"/>
      </xsl:when>
      <xsl:otherwise>
	<xsl:value-of select="$entry-and-beyond-for-class"/>
      </xsl:otherwise>
    </xsl:choose>
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
	  <xsl:call-template name="get-param-value-from-key">
	    <xsl:with-param name="parameter" select="$label.numeration.by.class"/>
	    <xsl:with-param name="key" select="$class"/>
	  </xsl:call-template>
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
  <xsl:template match="*" mode="title.markup">
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

  <!-- Get the "semantic" name for an HTML5 element (mirroring a DB element name, for mappings in the localizations),
       usually pulled from the @class value when the HTML5 element is not semantic enough -->
  <!-- There may be multiple class values present, e.g. (<section class="chapter purple">) so use XPath contains() to do checks,
       for lack of better alternative. -->
  <xsl:template name="semantic-name">
    <xsl:param name="node" select="."/>
    <xsl:choose>
      <xsl:when test="$node[self::h:section and contains(@class, 'acknowledgments')]">acknowledgments</xsl:when>
      <xsl:when test="$node[self::h:section and contains(@class, 'afterword')]">appendix</xsl:when>
      <xsl:when test="$node[self::h:section and contains(@class, 'bibliography')]">bibliography</xsl:when>
      <xsl:when test="$node[self::h:section and contains(@class, 'chapter')]">chapter</xsl:when>
      <xsl:when test="$node[self::h:section and contains(@class, 'colophon')]">colophon</xsl:when>
      <xsl:when test="$node[self::h:section and contains(@class, 'conclusion')]">appendix</xsl:when>
      <xsl:when test="$node[self::h:section and contains(@class, 'copyright-page')]">preface</xsl:when>
      <xsl:when test="$node[self::h:section and contains(@class, 'dedication')]">dedication</xsl:when>
      <xsl:when test="$node[self::h:section and contains(@class, 'foreword')]">preface</xsl:when>
      <xsl:when test="$node[self::h:section and contains(@class, 'glossary')]">glossary</xsl:when>
      <xsl:when test="$node[self::h:section and contains(@class, 'halftitlepage')]">preface</xsl:when>
      <xsl:when test="$node[self::h:section and contains(@class, 'index')]">index</xsl:when>
      <xsl:when test="$node[self::h:section and contains(@class, 'introduction')]">preface</xsl:when>
      <xsl:when test="$node[self::h:section and contains(@class, 'preface')]">preface</xsl:when>
      <xsl:when test="$node[self::h:section and contains(@class, 'titlepage')]">preface</xsl:when>
      <xsl:when test="$node[self::h:section and contains(@class, 'toc')]">toc</xsl:when>
      <xsl:when test="$node[self::h:section and contains(@class, 'sect1')]">sect1</xsl:when>
      <xsl:when test="$node[self::h:section and contains(@class, 'sect2')]">sect2</xsl:when>
      <xsl:when test="$node[self::h:section and contains(@class, 'sect3')]">sect3</xsl:when>
      <xsl:when test="$node[self::h:section and contains(@class, 'sect4')]">sect4</xsl:when>
      <xsl:when test="$node[self::h:section and contains(@class, 'sect5')]">sect5</xsl:when>
      <xsl:when test="$node[self::h:section]">section</xsl:when> <!-- for <section>, default to "section" -->
      <xsl:when test="$node[self::h:div and contains(@class, 'caution')]">caution</xsl:when>
      <xsl:when test="$node[self::h:div and contains(@class, 'equation')]">equation</xsl:when>
      <xsl:when test="$node[self::h:div and contains(@class, 'example')]">example</xsl:when>
      <xsl:when test="$node[self::h:div and contains(@class, 'footnote')]">footnote</xsl:when>
      <xsl:when test="$node[self::h:div and contains(@class, 'important')]">important</xsl:when>
      <xsl:when test="$node[self::h:div and contains(@class, 'note')]">note</xsl:when>
      <xsl:when test="$node[self::h:div and contains(@class, 'tip')]">tip</xsl:when>
      <xsl:when test="$node[self::h:div and contains(@class, 'part')]">part</xsl:when>
      <xsl:when test="$node[self::h:div and contains(@class, 'rearnote')]">footnote</xsl:when>
      <xsl:when test="$node[self::h:div and contains(@class, 'warning')]">warning</xsl:when>
      <xsl:when test="$node[self::h:div and @class]">
	<xsl:value-of select="$node/@class"/> <!-- for <div>, default to class value -->
      </xsl:when>
      <xsl:otherwise>
	<!-- For all other elements besides <section> and <div>, just use the local-name -->
	<xsl:value-of select="local-name($node)"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet> 
