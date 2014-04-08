<xsl:stylesheet version="1.0"
		xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns:exsl="http://exslt.org/common"
		xmlns:h="http://www.w3.org/1999/xhtml"
		xmlns="http://www.w3.org/1999/xhtml"
		extension-element-prefixes="exsl"
		exclude-result-prefixes="exsl h">

<!-- Template for id decoration on elements that need it for TOC and/or index generation. 
     Should be at a lower import level than tocgen.xsl and indexgen.xsl, so that those
     templates can override id-generation templates to add additional functionality, if needed -->

  <xsl:output method="xml"
              encoding="UTF-8"/>
  <xsl:preserve-space elements="*"/>

  <xsl:key name="footnote-nodes-by-id" match="h:span[@data-type='footnote']" use="@id"/>

  <!-- Elements that require ids: 
       * All <sections>
       * <div data-type="part">
       * All <a data-type="indexterm"> tags
    -->
  <!-- WARNING: If you need additional handling for these elements for other functionality,
       and you override this template elsewhere, make sure you add in id-decoration functionality -->
  <xsl:template match="h:section|h:div[contains(@data-type, 'part')]|h:aside|h:a[contains(@data-type, 'indexterm')]">
    <xsl:variable name="output-element-name">
      <xsl:call-template name="html.output.element"/>
    </xsl:variable>
    <xsl:element name="{$output-element-name}" namespace="http://www.w3.org/1999/xhtml">
      <xsl:apply-templates select="@*[not(local-name() = 'id')]"/>
      <xsl:attribute name="id">
	<xsl:call-template name="object.id"/>
      </xsl:attribute>
      <xsl:apply-templates select="." mode="pdf-bookmark"/>
      <xsl:apply-templates/>
      <xsl:if test="$process.footnotes = 1">
	<xsl:call-template name="generate-footnotes"/>
      </xsl:if>
    </xsl:element>
  </xsl:template>

  <xsl:template match="h:section[@data-type]/*[self::h:h1 or self::h:h2 or self::h:h3 or self::h:h4 or self::h:h5 or self::h:h6]|
		       h:section[@data-type]/h:header/*[self::h:h1 or self::h:h2 or self::h:h3 or self::h:h4 or self::h:h5 or self::h:h6]|
		       h:div[@data-type = 'part' or @data-type = 'example' or @data-type = 'equation']/*[self::h:h1 or self::h:h2 or self::h:h3 or self::h:h4 or self::h:h5 or self::h:h6]|
		       h:div[@data-type = 'part']/h:header/*[self::h:h1 or self::h:h2 or self::h:h3 or self::h:h4 or self::h:h5 or self::h:h6]">
    <xsl:param name="autogenerate.labels" select="$autogenerate.labels"/>
    <xsl:apply-templates select="." mode="process-heading">
      <xsl:with-param name="autogenerate.labels" select="$autogenerate.labels"/>
    </xsl:apply-templates>
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
      <!-- If the parameter $figure.border.div is enabled, and there is a figure caption, add a child div and put everything but the caption in it -->
      <xsl:choose>
	<xsl:when test="$figure.border.div = 1 and h:figcaption">
	  <!-- figcaption must be first or last; handle accordingly -->
	  <xsl:choose>
	    <xsl:when test="*[1][self::h:figcaption]">
	      <xsl:apply-templates select="h:figcaption"/>
	      <div class="border-box">
		<xsl:apply-templates select="*[not(self::h:figcaption)]"/>
	      </div>
	    </xsl:when>
	    <xsl:when test="*[last()][self::h:figcaption]">
	      <div class="border-box">
		<xsl:apply-templates select="*[not(self::h:figcaption)]"/>
	      </div>
	      <xsl:apply-templates select="h:figcaption"/>
	    </xsl:when>
	    <xsl:otherwise>
	      <!-- Uh oh, <figcaption> in an invalid location (not at beginning or end of <figure>) -->
	      <xsl:call-template name="log-message">
		<xsl:with-param name="type" select="'WARNING'"/>
		<xsl:with-param name="message">
		  <xsl:text>Error: figcaption for figure </xsl:text>
		  <xsl:value-of select="@id"/> 
		  <xsl:text> not at beginning or end of figure. Unable to add border box</xsl:text>
		</xsl:with-param>
	      </xsl:call-template>
	      <xsl:apply-templates/>
	    </xsl:otherwise>
	  </xsl:choose>
	</xsl:when>
	<xsl:otherwise>
	  <xsl:apply-templates/>
	</xsl:otherwise>
      </xsl:choose>
    </xsl:element>
  </xsl:template>

  <xsl:template match="h:caption">
    <xsl:apply-templates select="." mode="process-heading">
      <xsl:with-param name="labeled-element-semantic-name" select="'table'"/>
    </xsl:apply-templates>
  </xsl:template>

  <xsl:template match="h:figcaption">
    <xsl:apply-templates select="." mode="process-heading">
      <xsl:with-param name="labeled-element-semantic-name" select="'figure'"/>
      <xsl:with-param name="output-element-name">
	<xsl:call-template name="html.output.element"/>
      </xsl:with-param>
    </xsl:apply-templates>
  </xsl:template>

  <!-- Footnote handling -->
  <xsl:template match="h:span[@data-type='footnote']">
    <xsl:choose>
      <xsl:when test="$process.footnotes = 1">
	<xsl:call-template name="footnote-marker"/>
      </xsl:when>
      <xsl:otherwise>
	<xsl:copy>
	  <xsl:apply-templates select="@*|node()"/>
	</xsl:copy>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="footnote-marker">
    <a data-type="noteref">
      <xsl:attribute name="id">
	<xsl:call-template name="object.id"/>
	<xsl:text>-marker</xsl:text>
      </xsl:attribute>
      <xsl:attribute name="href">
	<xsl:call-template name="href.target"/>
      </xsl:attribute>
      <sup>
	<!-- Use numbers for footnotes -->
	<!-- ToDo: Parameterize for numeration type and/or symbols? -->
	<xsl:number count="h:span[@data-type='footnote']" level="any"/>
      </sup>
    </a>
  </xsl:template>

  <!-- Handling for footnoterefs a la DocBook (cross-references to an existing footnote) -->
  <xsl:template match="h:a[@data-type='footnoteref']">
    <xsl:choose>
      <xsl:when test="$process.footnotes = 1">
	<xsl:variable name="referenced-footnote-id">
	  <!-- Assuming that href is in the format href="#footnote_id" -->
	  <xsl:value-of select="substring-after(@href, '#')"/>
	</xsl:variable>
	<xsl:variable name="referenced-footnote" select="key('footnote-nodes-by-id', $referenced-footnote-id)"/>
	<xsl:choose>
	  <xsl:when test="count($referenced-footnote) &gt; 0">
	    <!-- Switch the context node to that of the referenced footnote -->
	    <xsl:for-each select="$referenced-footnote[1]">
	      <!-- Same general handling as regular footnote markers, except footnoterefs don't get ids -->
	      <a data-type="noteref">
		<xsl:attribute name="href">
		  <xsl:call-template name="href.target"/>
		</xsl:attribute>
		<sup>
		  <!-- Use numbers for footnotes -->
		  <!-- ToDo: Parameterize for numeration type and/or symbols? -->
		  <xsl:number count="h:span[@data-type='footnote']" level="any"/>
		</sup>
	  </a>
	    </xsl:for-each>
	  </xsl:when>
	  <xsl:otherwise>
	    <!-- Uh oh, couldn't find the corresponding footnote for the footnoteref -->
	    <xsl:call-template name="log-message">
	      <xsl:with-param name="type" select="'WARNING'"/>
	      <xsl:with-param name="message">
		<xsl:text>Error: Could not find footnote referenced by footnoteref link </xsl:text>
		<xsl:value-of select="@href"/>
		<xsl:text>. Footnote marker will not be generated.</xsl:text>
	      </xsl:with-param>
	    </xsl:call-template>
	  </xsl:otherwise>
	</xsl:choose>
      </xsl:when>
      <xsl:otherwise>
	<xsl:copy>
	  <xsl:apply-templates select="@*|node()"/>
	</xsl:copy>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="generate-footnotes">
    <!-- For standard, one-chunk output, we put all the footnotes at the end of the last chapter or appendix -->
    <!-- (Note that if there are no chapters or appendixes in the book, footnotes will not be generated properly. This can be changed
	 if we determine that there are other main-book-div types that can hold footnotes at the end of a book) --> 
    <xsl:if test="self::h:section[@data-type='chapter' or @data-type='appendix'] and not(following::h:section[@data-type='chapter' or @data-type='appendix']) and count(//h:span[@data-type='footnote']) > 0">
      <!-- Footnotes should be put in an aside by default, but we call html.output.element to see if <aside> should be remapped to something else -->
      <!-- Kludge-y way to get an aside element -->
      <xsl:variable name="aside-element">
	<aside/>
      </xsl:variable>
      <xsl:variable name="footnote-element-name">
	<xsl:call-template name="html.output.element">
	  <xsl:with-param name="node" select="exsl:node-set($aside-element)/*[1]"/>
	</xsl:call-template>
      </xsl:variable>
      <xsl:element name="{$footnote-element-name}" namespace="http://www.w3.org/1999/xhtml">
	<xsl:attribute name="data-type">footnotes</xsl:attribute>
	<xsl:apply-templates select="//h:span[@data-type='footnote']" mode="generate.footnote"/>
      </xsl:element>
    </xsl:if>
  </xsl:template>

  <xsl:template match="h:span[@data-type='footnote']" mode="generate.footnote">
    <p data-type="footnote">
      <xsl:attribute name="id">
	<xsl:call-template name="object.id"/>
      </xsl:attribute>
      <a>
	<xsl:attribute name="href">
	  <xsl:call-template name="href.target"/>
	  <xsl:text>-marker</xsl:text>
	</xsl:attribute>
	<sup>
	  <!-- Use numbers for footnotes -->
	  <!-- ToDo: Parameterize for numeration type and/or symbols? -->
	  <xsl:number count="h:span[@data-type='footnote']" level="any"/>
	</sup>
      </a>
      <xsl:text> </xsl:text>
      <xsl:apply-templates/>
    </p>
  </xsl:template>

  <xsl:template match="h:iframe|h:script">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
      <!-- Don't want to allow self-closing <iframe/> or <script/> tags, as many browsers don't like those -->
      <xsl:if test="not(node())">
	<xsl:text> </xsl:text>
      </xsl:if>
    </xsl:copy>
  </xsl:template>

</xsl:stylesheet> 
