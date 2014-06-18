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

  <xsl:variable name="lowercase" select="'abcdefghijklmnopqrstuvwxyz'"/>
  <xsl:variable name="uppercase" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZ'"/>

  <!-- key for getting elements by id -->
  <xsl:key name="id" match="*" use="@id"/>

  <!-- Default Rule; when no other templates are specified, copy direct to output -->
  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>

  <!-- Stylesheet for utility templates common to other stylesheets -->

  <!-- Template for generating standardized log messages -->
  <xsl:template name="log-message">
    <xsl:param name="type" select="'INFO'"/>
    <xsl:param name="message"/>
    <xsl:param name="terminate" select="'no'"/>

    <!-- Only output DEBUG messages if $verbose is true -->
    <xsl:if test="($type != 'DEBUG') or ($verbose = 1)">

      <xsl:variable name="log-output">----&#x0A;<xsl:value-of select="$type"/>: <xsl:value-of select="$message"/>&#x0A;----&#x0A;&#x0A;</xsl:variable>

      <!-- In XSLT 2.0, we could parameterize the value of the "terminate" attr, but that doesn't fly in XSLT 1.0,
	     hence kludge-y handling below -->
      <xsl:choose>
	<xsl:when test="$terminate = 'yes'">
	  <xsl:message terminate="yes">
	    <xsl:value-of select="$log-output"/>
	  </xsl:message>
	</xsl:when>
	<xsl:otherwise>
	  <xsl:message>
	    <xsl:value-of select="$log-output"/>
	  </xsl:message>
	</xsl:otherwise>
      </xsl:choose>
    </xsl:if>
  </xsl:template>
								      <!-- Generate target @href value pointing to given node -->
  <!-- Borrowed and adapted from xhtml/html.xsl in docbook-xsl stylesheets -->
  <xsl:template name="href.target">
    <xsl:param name="context" select="."/>
    <xsl:param name="object" select="."/>
    <xsl:param name="source-link-node"/>
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
  <xsl:template match="h:div[contains(@data-type, 'part')]|h:section" mode="label.markup">
    <xsl:variable name="current-node" select="."/>
    <xsl:if test="$label.section.with.ancestors != 0">
      <xsl:for-each select="ancestor::h:section">
	<xsl:call-template name="get-label-from-data-type">
	  <xsl:with-param name="data-type" select="@data-type"/>
	</xsl:call-template>
	<xsl:apply-templates select="$current-node" mode="intralabel.punctuation"/>
      </xsl:for-each>
    </xsl:if>
    <xsl:call-template name="get-label-from-data-type">
      <xsl:with-param name="data-type" select="@data-type"/>
    </xsl:call-template>
  </xsl:template>

  <xsl:template match="h:table" mode="label.markup">
    <xsl:param name="label.formal.with.ancestor" select="$label.formal.with.ancestor"/>
    <xsl:choose>
      <xsl:when test="$label.formal.with.ancestor != 0">
	<xsl:apply-templates select="(ancestor::h:section[contains(@data-type, 'acknowledgments') or
				     contains(@data-type, 'afterword') or
				     contains(@data-type, 'appendix') or
				     contains(@data-type, 'bibliography') or
				     contains(@data-type, 'chapter') or
				     contains(@data-type, 'colophon') or
				     contains(@data-type, 'conclusion') or
				     contains(@data-type, 'copyright-page') or
				     contains(@data-type, 'dedication') or
				     contains(@data-type, 'foreword') or
				     contains(@data-type, 'glossary') or
				     contains(@data-type, 'halftitlepage') or
				     contains(@data-type, 'index') or
				     contains(@data-type, 'introduction') or
				     contains(@data-type, 'preface') or
				     contains(@data-type, 'titlepage') or
				     contains(@data-type, 'toc')]|
				     ancestor::h:div[@data-type = 'part'])[last()]" mode="label.markup"/>
	<xsl:apply-templates select="." mode="intralabel.punctuation"/>
	<xsl:number count="h:table[h:caption[. != '']]" from="h:section[contains(@data-type, 'acknowledgments') or
					   contains(@data-type, 'afterword') or
					   contains(@data-type, 'appendix') or
					   contains(@data-type, 'bibliography') or
					   contains(@data-type, 'chapter') or
					   contains(@data-type, 'colophon') or
					   contains(@data-type, 'conclusion') or
					   contains(@data-type, 'copyright-page') or
					   contains(@data-type, 'dedication') or
					   contains(@data-type, 'foreword') or
					   contains(@data-type, 'glossary') or
					   contains(@data-type, 'halftitlepage') or
					   contains(@data-type, 'index') or
					   contains(@data-type, 'introduction') or
					   contains(@data-type, 'preface') or
					   contains(@data-type, 'titlepage') or
					   contains(@data-type, 'toc')]|
					   h:div[contains(@data-type, 'part')]" level="any" format="1"/>
      </xsl:when>
      <xsl:otherwise>
	<xsl:number count="h:table[h:caption[. != '']]" level="any" format="1"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="h:figure" mode="label.markup">
    <xsl:param name="label.formal.with.ancestor" select="$label.formal.with.ancestor"/>
    <xsl:choose>
      <xsl:when test="$label.formal.with.ancestor != 0">
	<xsl:apply-templates select="(ancestor::h:section[contains(@data-type, 'acknowledgments') or
				     contains(@data-type, 'afterword') or
				     contains(@data-type, 'appendix') or
				     contains(@data-type, 'bibliography') or
				     contains(@data-type, 'chapter') or
				     contains(@data-type, 'colophon') or
				     contains(@data-type, 'conclusion') or
				     contains(@data-type, 'copyright-page') or
				     contains(@data-type, 'dedication') or
				     contains(@data-type, 'foreword') or
				     contains(@data-type, 'glossary') or
				     contains(@data-type, 'halftitlepage') or
				     contains(@data-type, 'index') or
				     contains(@data-type, 'introduction') or
				     contains(@data-type, 'preface') or
				     contains(@data-type, 'titlepage') or
				     contains(@data-type, 'toc')]|
				     ancestor::h:div[@data-type = 'part'])[last()]" mode="label.markup"/>
	<xsl:apply-templates select="." mode="intralabel.punctuation"/>
	<xsl:number count="h:figure[not(contains(@data-type, 'cover'))][h:figcaption[. != '']]" from="h:section[contains(@data-type, 'acknowledgments') or
					   contains(@data-type, 'afterword') or
					   contains(@data-type, 'appendix') or
					   contains(@data-type, 'bibliography') or
					   contains(@data-type, 'chapter') or
					   contains(@data-type, 'colophon') or
					   contains(@data-type, 'conclusion') or
					   contains(@data-type, 'copyright-page') or
					   contains(@data-type, 'dedication') or
					   contains(@data-type, 'foreword') or
					   contains(@data-type, 'glossary') or
					   contains(@data-type, 'halftitlepage') or
					   contains(@data-type, 'index') or
					   contains(@data-type, 'introduction') or
					   contains(@data-type, 'preface') or
					   contains(@data-type, 'titlepage') or
					   contains(@data-type, 'toc')]|
					   h:div[contains(@data-type, 'part')]" level="any" format="1"/>
      </xsl:when>
      <xsl:otherwise>
	<xsl:number count="h:figure[not(contains(@data-type, 'cover'))][h:figcaption[. != '']]" level="any" format="1"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="h:div[contains(@data-type, 'example')]" mode="label.markup">
    <xsl:param name="label.formal.with.ancestor" select="$label.formal.with.ancestor"/>
    <xsl:choose>
      <xsl:when test="$label.formal.with.ancestor != 0">
	<xsl:apply-templates select="(ancestor::h:section[contains(@data-type, 'acknowledgments') or
				     contains(@data-type, 'afterword') or
				     contains(@data-type, 'appendix') or
				     contains(@data-type, 'bibliography') or
				     contains(@data-type, 'chapter') or
				     contains(@data-type, 'colophon') or
				     contains(@data-type, 'conclusion') or
				     contains(@data-type, 'copyright-page') or
				     contains(@data-type, 'dedication') or
				     contains(@data-type, 'foreword') or
				     contains(@data-type, 'glossary') or
				     contains(@data-type, 'halftitlepage') or
				     contains(@data-type, 'index') or
				     contains(@data-type, 'introduction') or
				     contains(@data-type, 'preface') or
				     contains(@data-type, 'titlepage') or
				     contains(@data-type, 'toc')]|
				     ancestor::h:div[@data-type = 'part'])[last()]" mode="label.markup"/>
	<xsl:apply-templates select="." mode="intralabel.punctuation"/>
	<xsl:number count="h:div[@data-type='example']" from="h:section[contains(@data-type, 'acknowledgments') or
					   contains(@data-type, 'afterword') or
					   contains(@data-type, 'appendix') or
					   contains(@data-type, 'bibliography') or
					   contains(@data-type, 'chapter') or
					   contains(@data-type, 'colophon') or
					   contains(@data-type, 'conclusion') or
					   contains(@data-type, 'copyright-page') or
					   contains(@data-type, 'dedication') or
					   contains(@data-type, 'foreword') or
					   contains(@data-type, 'glossary') or
					   contains(@data-type, 'halftitlepage') or
					   contains(@data-type, 'index') or
					   contains(@data-type, 'introduction') or
					   contains(@data-type, 'preface') or
					   contains(@data-type, 'titlepage') or
					   contains(@data-type, 'toc')]|
					   h:div[contains(@data-type, 'part')]" level="any" format="1"/>
      </xsl:when>
      <xsl:otherwise>
	<xsl:number count="h:div[contains(@data-type, 'example')]" level="any" format="1"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- No label markup for figures or tables with empty captions -->
  <xsl:template match="h:figure[h:figcaption[normalize-space(.) = '']]|
		       h:table[h:caption[normalize-space(.) = '']]" 
		mode="label.markup"/>

  <xsl:template match="*" mode="label.markup"/>

  <!-- Intralabel punctuation templates.
       NOTE: These templates are based on the element being labeled (i.e., the last number in the label
    -->
  
  <xsl:template match="*" mode="intralabel.punctuation">
    <xsl:text>.</xsl:text>
  </xsl:template>

  <xsl:template match="h:figure|h:table|h:div[@data-type='example']" mode="intralabel.punctuation">
    <xsl:text>-</xsl:text>
  </xsl:template>

  <!-- Template that pulls a value from a key/value list in an <xsl:param> that looks like this: 
       key1:value1
       key2:value2
    -->
  <xsl:template name="get-param-value-from-key">
    <xsl:param name="parameter"/>
    <xsl:param name="key"/>
    <xsl:variable name="entry-and-beyond">
      <!-- Gets the value corresponding to specified key...and everything beyond -->
      <xsl:value-of select="substring-after(normalize-space($parameter), concat($key, ':'))"/>
    </xsl:variable>
    <!-- Then we further narrow to just the key value -->
    <xsl:choose>
      <xsl:when test="contains($entry-and-beyond, ' ')">
	<xsl:value-of select="substring-before($entry-and-beyond, ' ')"/>
      </xsl:when>
      <xsl:otherwise>
	<xsl:value-of select="$entry-and-beyond"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="get-label-from-data-type">
    <xsl:param name="data-type"/>
    <xsl:param name="numeration-format"/>

    <!-- Calculate numeration format -->
    <xsl:variable name="calculated-numeration-format">
      <xsl:choose>
	<xsl:when test="$numeration-format != ''">
	  <xsl:value-of select="$numeration-format"/>
	</xsl:when>
	<xsl:otherwise>
	  <xsl:call-template name="get-param-value-from-key">
	    <xsl:with-param name="parameter" select="$label.numeration.by.data-type"/>
	    <xsl:with-param name="key" select="$data-type"/>
	  </xsl:call-template>
	</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <!-- Now generate number using format -->
    <!-- ToDo: logic for section labeling with parent-element number in label (e.g., 1.8) -->
    <xsl:choose>
      <!-- I wish XSL allowed variables in @format attribute -->
      <xsl:when test="$calculated-numeration-format = '1'">
	<xsl:number count="*[@data-type = $data-type]" format="1" level="any"/>
      </xsl:when>
      <xsl:when test="$calculated-numeration-format = '01'">
	<xsl:number count="*[@data-type = $data-type]" format="01" level="any"/>
      </xsl:when>
      <xsl:when test="$calculated-numeration-format = 'a'">
	<xsl:number count="*[@data-type = $data-type]" format="a" level="any"/>
      </xsl:when>
      <xsl:when test="$calculated-numeration-format = 'A'">
	<xsl:number count="*[@data-type = $data-type]" format="A" level="any"/>
      </xsl:when>
      <xsl:when test="$calculated-numeration-format = 'i'">
	<xsl:number count="*[@data-type = $data-type]" format="i" level="any"/>
      </xsl:when>
      <xsl:when test="$calculated-numeration-format = 'I'">
	<xsl:number count="*[@data-type = $data-type]" format="I" level="any"/>
      </xsl:when>
      <xsl:when test="$calculated-numeration-format = 'none'"/>
      <xsl:otherwise>
	<!-- If $calculated-numeration-format doesn't match above values or is blank, no label can be generated -->
	<xsl:choose>
	  <xsl:when test="normalize-space($calculated-numeration-format) = ''">
	    <xsl:call-template name="log-message">
	      <xsl:with-param name="type" select="'DEBUG'"/>
	      <xsl:with-param name="message">
		<xsl:text>No label numeration format specified for </xsl:text>
		<xsl:value-of select="$data-type"/>
		<xsl:text>: skipping label</xsl:text>
	      </xsl:with-param>
	    </xsl:call-template>
	  </xsl:when>
	  <xsl:otherwise>
	    <xsl:call-template name="log-message">
	      <xsl:with-param name="type" select="'WARNING'"/>
	      <xsl:with-param name="message">
		<xsl:text>Unable to generate label for </xsl:text>
		<xsl:value-of select="$data-type"/> 
		<xsl:text> with numeration format </xsl:text>
		<xsl:value-of select="$calculated-numeration-format"/>
		<xsl:text>.</xsl:text>
	      </xsl:with-param>
	    </xsl:call-template>
	  </xsl:otherwise>
	</xsl:choose>
      </xsl:otherwise>
    </xsl:choose>    	
  </xsl:template>

  <!-- Logic for generating titles; default handling is to grab the first <h1>-<h6> content -->
  <xsl:template match="*" mode="title.markup">
    <xsl:choose>
      <xsl:when test="self::h:section[@data-type='index' and not(h:h1|h:h2|h:h3|h:h4|h:h5|h:h6|h:header/h:h1|h:header/h:h2|h:header/h:h3|h:header/h:h4|h:header/h:h5|h:header/h:h6)]">
	<xsl:call-template name="get-localization-value">
	  <xsl:with-param name="gentext-key" select="'index'"/>
	</xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
	<xsl:apply-templates select="(h:h1|h:h2|h:h3|h:h4|h:h5|h:h6|
				      h:header/h:h1|h:header/h:h2|h:header/h:h3|h:header/h:h4|h:header/h:h5|h:header/h:h6)[1]/node()"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Logic for processing headings (e.g., h1-h6, caption, figcaption) -->
  <xsl:template match="*" mode="process-heading">
    <xsl:param name="autogenerate.labels" select="$autogenerate.labels"/>
    <!-- Labeled element is typically the parent element of the heading (e.g., <section> or <figure>) -->
    <xsl:param name="labeled-element" select="(parent::h:header/parent::*|parent::*[not(self::h:header)])[1]"/>
    <!-- Labeled element semantic name is typically the parent element of the heading's @data-type -->
    <xsl:param name="labeled-element-semantic-name" select="(parent::h:header/parent::*|parent::*[not(self::h:header)])[1]/@data-type"/>
    <!-- Name for output heading element; same as current node name by default -->
    <xsl:param name="output-element-name" select="local-name(.)"/>
    <xsl:element name="{$output-element-name}" namespace="http://www.w3.org/1999/xhtml">
      <xsl:apply-templates select="@*"/>
      <xsl:if test="$autogenerate.labels = 1">
	<xsl:variable name="heading.label">
	  <xsl:apply-templates select="$labeled-element" mode="label.markup"/>
	</xsl:variable>
	<xsl:if test="$heading.label != ''">
	  <span class="label">
	    <xsl:variable name="element-labelname">
	      <xsl:call-template name="get-localization-value">
		<xsl:with-param name="gentext-key">
		  <xsl:value-of select="$labeled-element-semantic-name"/>
		</xsl:with-param>
	      </xsl:call-template>
	    </xsl:variable>
	    <xsl:if test="normalize-space($element-labelname) != ''">
	      <xsl:value-of select="concat($element-labelname, ' ')"/>
	    </xsl:if>
	    <xsl:value-of select="$heading.label"/>
	    <xsl:value-of select="$label.and.title.separator"/>
	  </span>
	</xsl:if>
      </xsl:if>
      <xsl:apply-templates/>
    </xsl:element>
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
       usually pulled from the @data-type value when the HTML5 element is not semantic enough -->
  <!-- Uses XPath contains() function instead of a straight = comparison, to try to be more flexible in case @data-type
       values are funky -->
  <xsl:template name="semantic-name">
    <xsl:param name="node" select="."/>
    <xsl:choose>
      <xsl:when test="$node[self::h:section and contains(@data-type, 'acknowledgments')]">acknowledgments</xsl:when>
      <xsl:when test="$node[self::h:section and contains(@data-type, 'afterword')]">appendix</xsl:when>
      <xsl:when test="$node[self::h:section and contains(@data-type, 'appendix')]">appendix</xsl:when>
      <xsl:when test="$node[self::h:section and contains(@data-type, 'bibliography')]">bibliography</xsl:when>
      <xsl:when test="$node[self::h:section and contains(@data-type, 'chapter')]">chapter</xsl:when>
      <xsl:when test="$node[self::h:section and contains(@data-type, 'colophon')]">colophon</xsl:when>
      <xsl:when test="$node[self::h:section and contains(@data-type, 'conclusion')]">appendix</xsl:when>
      <xsl:when test="$node[self::h:section and contains(@data-type, 'copyright-page')]">preface</xsl:when>
      <xsl:when test="$node[self::h:section and contains(@data-type, 'dedication')]">dedication</xsl:when>
      <xsl:when test="$node[self::h:section and contains(@data-type, 'foreword')]">preface</xsl:when>
      <xsl:when test="$node[self::h:section and contains(@data-type, 'glossary')]">glossary</xsl:when>
      <xsl:when test="$node[self::h:section and contains(@data-type, 'halftitlepage')]">preface</xsl:when>
      <xsl:when test="$node[self::h:section and contains(@data-type, 'index')]">index</xsl:when>
      <xsl:when test="$node[self::h:section and contains(@data-type, 'introduction')]">preface</xsl:when>
      <xsl:when test="$node[self::h:section and contains(@data-type, 'preface')]">preface</xsl:when>
      <xsl:when test="$node[self::h:section and contains(@data-type, 'titlepage')]">preface</xsl:when>
      <xsl:when test="$node[self::h:section and contains(@data-type, 'toc')]">toc</xsl:when>
      <xsl:when test="$node[self::h:section and contains(@data-type, 'sect1')]">sect1</xsl:when>
      <xsl:when test="$node[self::h:section and contains(@data-type, 'sect2')]">sect2</xsl:when>
      <xsl:when test="$node[self::h:section and contains(@data-type, 'sect3')]">sect3</xsl:when>
      <xsl:when test="$node[self::h:section and contains(@data-type, 'sect4')]">sect4</xsl:when>
      <xsl:when test="$node[self::h:section and contains(@data-type, 'sect5')]">sect5</xsl:when>
      <xsl:when test="$node[self::h:section]">section</xsl:when> <!-- for <section>, default to "section" -->
      <xsl:when test="$node[self::h:div and contains(@data-type, 'caution')]">caution</xsl:when>
      <xsl:when test="$node[self::h:div and contains(@data-type, 'equation')]">equation</xsl:when>
      <xsl:when test="$node[self::h:div and contains(@data-type, 'example')]">example</xsl:when>
      <xsl:when test="$node[self::h:div and contains(@data-type, 'footnote')]">footnote</xsl:when>
      <xsl:when test="$node[self::h:div and contains(@data-type, 'important')]">important</xsl:when>
      <xsl:when test="$node[self::h:div and contains(@data-type, 'note')]">note</xsl:when>
      <xsl:when test="$node[self::h:div and contains(@data-type, 'tip')]">tip</xsl:when>
      <xsl:when test="$node[self::h:div and contains(@data-type, 'part')]">part</xsl:when>
      <xsl:when test="$node[self::h:div and contains(@data-type, 'rearnote')]">footnote</xsl:when>
      <xsl:when test="$node[self::h:div and contains(@data-type, 'warning')]">warning</xsl:when>
      <xsl:when test="$node[self::h:div and @data-type]">
	<xsl:value-of select="$node/@data-type"/> <!-- for <div>, default to @data-type value -->
      </xsl:when>
      <xsl:when test="$node[self::h:aside]">
	<xsl:choose>
	  <xsl:when test="$node[@data-type]">
	    <xsl:value-of select="$node/@data-type"/>
	  </xsl:when>
	  <xsl:otherwise>sidebar</xsl:otherwise>
	</xsl:choose>
      </xsl:when>
      <xsl:otherwise>
	<!-- For all other elements besides <section> and <div>, just use the local-name -->
	<xsl:value-of select="local-name($node)"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="html.output.element">
    <!-- Logic to decide which HTML element to output for a given source element. -->
    <xsl:param name="node" select="."/>
    <xsl:param name="html4.structural.elements" select="$html4.structural.elements"/>
    <xsl:choose>
      <!-- If $html4.structural.elements is enabled, HTML5 <section> and <figure> elements are replaced with a <div> -->
      <xsl:when test="$html4.structural.elements = 1">
	<xsl:choose>
	  <xsl:when test="$node[self::h:figure or self::h:section or self::h:aside]">
	    <xsl:text>div</xsl:text>
	  </xsl:when>
	  <xsl:when test="$node[self::h:figcaption]">
	    <xsl:text>h6</xsl:text>
	  </xsl:when>
	  <xsl:otherwise>
	    <!-- No change in element name for other elements -->
	    <xsl:value-of select="local-name($node)"/>
	  </xsl:otherwise>
	</xsl:choose>
      </xsl:when>
      <xsl:otherwise>
	<!-- Otherwise, no change in element name -->
	<xsl:value-of select="local-name($node)"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Handling for PDF bookmark attribute generation (@data-pdf-bookmark) -->
  <xsl:template match="h:div[@data-type='part']" mode="pdf-bookmark">
    <xsl:choose>
      <xsl:when test="@data-pdf-bookmark">
	<xsl:attribute name="data-pdf-bookmark" select="@data-pdf-bookmark"/>
      </xsl:when>
      <xsl:when test="h:h1 or h:header/h:h1">
	<xsl:variable name="processed-heading">
	  <xsl:apply-templates select="(h:h1|h:header/h:h1)[1]" mode="process-heading">
	    <xsl:with-param name="autogenerate.labels" select="$autogenerate.pdf.bookmark.labels"/>
	  </xsl:apply-templates>
	</xsl:variable>
	<xsl:attribute name="data-pdf-bookmark">
	  <xsl:value-of select="$processed-heading"/>
	</xsl:attribute>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="h:section[@data-type='sect2']" mode="pdf-bookmark">
    <xsl:choose>
      <xsl:when test="@data-pdf-bookmark">
	<xsl:attribute name="data-pdf-bookmark" select="@data-pdf-bookmark"/>
      </xsl:when>
      <xsl:when test="h:h2 or h:header/h:h2">
	<xsl:variable name="processed-heading">
	  <xsl:apply-templates select="(h:h2|h:header/h:h2)[1]" mode="process-heading">
	    <xsl:with-param name="autogenerate.labels" select="$autogenerate.pdf.bookmark.labels"/>
	  </xsl:apply-templates>
	</xsl:variable>
	<xsl:attribute name="data-pdf-bookmark">
	  <xsl:value-of select="$processed-heading"/>
	</xsl:attribute>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="h:section[@data-type='sect3']" mode="pdf-bookmark">
    <xsl:choose>
      <xsl:when test="@data-pdf-bookmark">
	<xsl:attribute name="data-pdf-bookmark" select="@data-pdf-bookmark"/>
      </xsl:when>
      <xsl:when test="h:h3 or h:header/h:h3">
	<xsl:variable name="processed-heading">
	  <xsl:apply-templates select="(h:h3|h:header/h:h3)[1]" mode="process-heading">
	    <xsl:with-param name="autogenerate.labels" select="$autogenerate.pdf.bookmark.labels"/>
	  </xsl:apply-templates>
	</xsl:variable>
	<xsl:attribute name="data-pdf-bookmark">
	  <xsl:value-of select="$processed-heading"/>
	</xsl:attribute>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="h:section[@data-type='sect4']" mode="pdf-bookmark">
    <xsl:choose>
      <xsl:when test="@data-pdf-bookmark">
	<xsl:attribute name="data-pdf-bookmark" select="@data-pdf-bookmark"/>
      </xsl:when>
      <xsl:when test="h:h4 or h:header/h:h4">
	<xsl:variable name="processed-heading">
	  <xsl:apply-templates select="(h:h4|h:header/h:h4)[1]" mode="process-heading">
	    <xsl:with-param name="autogenerate.labels" select="$autogenerate.pdf.bookmark.labels"/>
	  </xsl:apply-templates>
	</xsl:variable>
	<xsl:attribute name="data-pdf-bookmark">
	  <xsl:value-of select="$processed-heading"/>
	</xsl:attribute>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="h:section[@data-type='sect5']" mode="pdf-bookmark">
    <xsl:choose>
      <xsl:when test="@data-pdf-bookmark">
	<xsl:attribute name="data-pdf-bookmark" select="@data-pdf-bookmark"/>
      </xsl:when>
      <xsl:when test="h:h5 or h:header/h:h5">
	<xsl:variable name="processed-heading">
	  <xsl:apply-templates select="(h:h5|h:header/h:h5)[1]" mode="process-heading">
	    <xsl:with-param name="autogenerate.labels" select="$autogenerate.pdf.bookmark.labels"/>
	  </xsl:apply-templates>
	</xsl:variable>
	<xsl:attribute name="data-pdf-bookmark">
	  <xsl:value-of select="$processed-heading"/>
	</xsl:attribute>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="h:section" mode="pdf-bookmark">
    <xsl:choose>
      <xsl:when test="@data-pdf-bookmark">
	<xsl:attribute name="data-pdf-bookmark" select="@data-pdf-bookmark"/>
      </xsl:when>
      <xsl:when test="h:h1 or h:header/h:h1">
	<xsl:variable name="processed-heading">
	  <xsl:apply-templates select="(h:h1|h:header/h:h1)[1]" mode="process-heading">
	    <xsl:with-param name="autogenerate.labels" select="$autogenerate.pdf.bookmark.labels"/>
	  </xsl:apply-templates>
	</xsl:variable>
	<xsl:attribute name="data-pdf-bookmark">
	  <xsl:value-of select="$processed-heading"/>
	</xsl:attribute>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <!-- Default rule for PDF bookmarks; do nothing for elements that aren't sections or Part divs -->
  <xsl:template match="*" mode="pdf-bookmark"/>

  <!-- Templates for handling of class values -->
  <xsl:template match="*" mode="class.attribute">
    <xsl:param name="xref.elements.pagenum.in.class" select="$xref.elements.pagenum.in.class"/>
    <xsl:param name="xref.target"/>
    <xsl:param name="class" select="@class"/>
    <xsl:variable name="class.value">
      <xsl:apply-templates select="." mode="class.value">
	<xsl:with-param name="class" select="$class"/>
	<xsl:with-param name="xref.elements.pagenum.in.class" select="$xref.elements.pagenum.in.class"/>
	<xsl:with-param name="xref.target" select="$xref.target"/>
      </xsl:apply-templates>
    </xsl:variable>
    <xsl:if test="normalize-space($class.value) != ''">
      <xsl:attribute name="class">
	<xsl:value-of select="$class.value"/>
      </xsl:attribute>
    </xsl:if>
  </xsl:template>
  
  <!-- Default is to use supplied $class param as @class value -->
  <xsl:template match="*" mode="class.value">
    <xsl:param name="class" select="@class"/>
    <xsl:param name="xref.elements.pagenum.in.class" select="$xref.elements.pagenum.in.class"/>
    <xsl:param name="xref.target"/>
    <xsl:value-of select="$class"/>
  </xsl:template>

  <xsl:template match="h:a[@data-type='xref']" mode="class.value">
    <xsl:param name="class" select="@class"/>
    <xsl:param name="xref.elements.pagenum.in.class" select="$xref.elements.pagenum.in.class"/>
    <xsl:param name="xref.target"/>
    <xsl:choose>
      <!-- If there's an xref target, process that to determine whether a pagenum value should be added to the class -->
      <xsl:when test="$xref.target">
	<xsl:variable name="xref.target.semantic.name">
	  <xsl:call-template name="semantic-name">
	    <xsl:with-param name="node" select="$xref.target"/>
	  </xsl:call-template>
	</xsl:variable>
	<xsl:if test="$class != ''">
	  <xsl:value-of select="$class"/>
	</xsl:if>
	<!-- Check if target semantic name is in list of XREF elements containing pagenum -->
	<!-- ToDo: Consider modularizing logic into separate function if needed for reuse elsewhere -->
	<xsl:variable name="space-delimited-pagenum-elements" select="concat(' ', normalize-space($xref.elements.pagenum.in.class), ' ')"/>
	<xsl:variable name="substring-before-target-name" select="substring-before($space-delimited-pagenum-elements, $xref.target.semantic.name)"/>
	<xsl:variable name="substring-after-target-name" select="substring-after($space-delimited-pagenum-elements, $xref.target.semantic.name)"/>
	<!-- Make sure a match is both preceded and followed by a space -->
	<xsl:if test="substring($substring-after-target-name, 1, 1) and
		      substring($substring-before-target-name, string-length($substring-before-target-name), 1)">
	  <xsl:if test="$class != ''"><xsl:text> </xsl:text></xsl:if>
	  <xsl:text>pagenum</xsl:text>
	</xsl:if>
      </xsl:when>
      <xsl:otherwise>
	<xsl:if test="$class != ''">
	  <xsl:value-of select="$class"/>
	</xsl:if>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Returns 1 when a text node contains only whitespace (defined as standard space chars or nbsp chars) -->
  <!-- Otherwise returns 0 -->
  <xsl:template name="whitespace-only-in-text">
    <xsl:param name="text.content" select="."/>
    <xsl:choose>
      <!-- Fine to consider empty text nodes to be whitespace-only; facilitates recursion here -->
      <xsl:when test="string-length($text.content) = 0">1</xsl:when>
      <xsl:when test="(substring($text.content, 1, 1) = ' ') or 
		      (substring($text.content, 1, 1) = '&#xa0;')">
	<!-- If first character is a whitespace char, recurse on rest of string to see if it's all whitespace -->
	<xsl:call-template name="whitespace-only-in-text">
	  <xsl:with-param name="text.content">
	    <xsl:value-of select="substring($text.content, 2)"/>
	  </xsl:with-param>
	</xsl:call-template>
      </xsl:when>
      <!-- Otherwise, there's at least 1 text character, so return 0 (false) -->
      <xsl:otherwise>0</xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet> 
