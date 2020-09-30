<xsl:stylesheet version="1.0"
		xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns:dc="http://purl.org/dc/elements/1.1/"
		xmlns:ncx="http://www.daisy.org/z3986/2005/ncx/"
		xmlns:dcterms="http://purl.org/dc/terms/"
		xmlns:opf="http://www.idpf.org/2007/opf"
		xmlns:m="http://www.w3.org/1998/Math/MathML"
		xmlns:svg="http://www.w3.org/2000/svg"
		xmlns:date="http://exslt.org/dates-and-times"
		xmlns:exsl="http://exslt.org/common"
		xmlns:set="http://exslt.org/sets"
		xmlns:e="http://github.com/oreillymedia/epubrenderer"
		xmlns:epub="http://www.idpf.org/2007/ops"
		xmlns:h="http://www.w3.org/1999/xhtml"
		xmlns:htmlbook="https://github.com/oreillymedia/HTMLBook"
		xmlns:func="http://exslt.org/functions"
		xmlns="http://www.w3.org/1999/xhtml"
		extension-element-prefixes="exsl func set date"
		exclude-result-prefixes="date e exsl func h htmlbook m ncx opf set svg">

  <!-- Generate an EPUB from HTMLBook source. -->
  <!-- ToDo: Support for adding the "scripted" property in the manifest to content that contains JS -->
  <!-- ToDo: Change <section> elements to <div>s for backward compatiblity with HTML5-non-compliant ereaders -->

  <!-- Imports chunk.xsl -->
  <xsl:import href="chunk.xsl"/>

  <xsl:output method="xml"
              encoding="UTF-8"/>
  <xsl:preserve-space elements="*"/>

  <xsl:include href="ncx.xsl"/>
  <xsl:include href="opf.xsl"/>

  <!-- Nodes by name -->
  <xsl:key name="nodes-by-name" match="*" use="local-name()"/>

  <!-- EPUB-specific parameters -->
  <xsl:param name="opf.namespace" select="'http://www.idpf.org/2007/opf'"/>

  <!-- mimetype mapping; feel free to modify existing mapping or point to different mapping document -->
  <xsl:param name="mimetypes-by-file-extension-mapping" select="document('mimetypes-by-file-extension.xml')"/>

  <!-- list of valid epub:type values; feel free to modify existing mapping or point to different mapping document -->
  <xsl:param name="valid.epub.type.values" select="document('valid_epub_types.xml')"/>

  <xsl:param name="metadata.unique-identifier">
    <!-- By default, try to pull from meta element in head -->
    <xsl:value-of select="//h:head/h:meta[contains(@name, 'identifier')][1]/@content"/>
  </xsl:param>

  <xsl:param name="computed.identifier">
    <xsl:value-of select="$metadata.unique-identifier"/>
    <!-- If no identifier supplied, add a default value to ensure validity -->
    <xsl:if test="not($metadata.unique-identifier) or normalize-space($metadata.unique-identifier) = ''">
      <xsl:value-of select="concat('randomid-', generate-id())"/>
    </xsl:if>
  </xsl:param>

  <!-- ID to use on the dc:identifier element corresponding to the EPUB unique identifier -->
  <xsl:param name="metadata.unique-identifier.id" select="'pub-identifier'"/>

  <xsl:param name="opf.filename" select="'content.opf'"/>

  <!-- Generate <guide> element in OPF file (for EPUB 2 compatibility -->
  <xsl:param name="generate.guide" select="1"/>

  <!-- Outputdir is the main content dir -->
  <xsl:param name="outputdir" select="'OEBPS'"/>

  <xsl:param name="metadata.title">
    <!-- Look for title first in head, then as child of body -->
    <xsl:value-of select="(//h:head/h:title|//h:body/h:h1|//h:body/h:header/h:h1)[1]"/>
  </xsl:param>

  <xsl:param name="metadata.language">
    <xsl:value-of select="$book-language"/>
  </xsl:param>

  <!-- By default, don't generate a root chunk (index.html) if book has a titlepage already -->
  <xsl:param name="generate.root.chunk">
    <xsl:choose>
      <xsl:when test="//h:section[@data-type='titlepage']">0</xsl:when>
      <xsl:otherwise>1</xsl:otherwise>
    </xsl:choose>
  </xsl:param>

  <!-- borrowed from docbook-xsl epub3/epub3-element-mods.xsl -->
  <xsl:param name="metadata.modified">
    <xsl:variable name="local.datetime" select="date:date-time()"/>
    <xsl:variable name="utc.datetime">
      <xsl:call-template name="convert.date.to.utc">
	<xsl:with-param name="date" select="$local.datetime"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="string-length($utc.datetime) != 0">
        <xsl:value-of select="$utc.datetime"/>
      </xsl:when>
      <xsl:otherwise>
	<xsl:call-template name="log-message">
	  <xsl:with-param name="type" select="'ERROR'"/>
	  <xsl:with-param name="terminate" select="'yes'"/>
	  <xsl:with-param name="message">
	    <xsl:text>No last-modified date value could be determined, </xsl:text>
	    <xsl:text>so cannot output required meta element with </xsl:text>
	    <xsl:text>dcterms:modified attribute. Exiting.</xsl:text>
	  </xsl:with-param>
	</xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:param>

  <xsl:param name="metadata.rights">
    <!-- By default, try to pull from meta element in head -->
    <xsl:value-of select="//h:head/h:meta[contains(@name, 'rights')][1]/@content"/>
  </xsl:param>

  <xsl:param name="metadata.publisher">
    <!-- By default, try to pull from meta element in head -->
    <xsl:value-of select="//h:head/h:meta[contains(@name, 'publisher')][1]/@content"/>
  </xsl:param>

  <xsl:param name="metadata.subject">
    <!-- By default, try to pull from meta element in head -->
    <xsl:value-of select="//h:head/h:meta[contains(@name, 'subject')][1]/@content"/>
  </xsl:param>

  <xsl:param name="metadata.date">
    <!-- By default, try to pull from meta element in head -->
    <xsl:value-of select="//h:head/h:meta[contains(@name, 'date')][1]/@content"/>
  </xsl:param>

  <xsl:param name="metadata.description">
    <!-- By default, try to pull from meta element in head -->
    <xsl:value-of select="//h:head/h:meta[contains(@name, 'description')][1]/@content"/>
  </xsl:param>

  <!-- By default, try to pull from meta element in head -->
  <xsl:param name="metadata.contributors" select="//h:head/h:meta[contains(@name, 'contributor')]"/>

  <xsl:param name="metadata.creators" select="//h:head/h:meta[contains(@name, 'creator') or contains(@name, 'author')]"/>

  <!-- Id to use to reference cover image -->
  <xsl:param name="epub.cover.image.id" select="'cover-image'"/>

  <!-- ID to use to reference cover filename -->
  <xsl:param name="epub.cover.html.id" select="'cover'"/>

  <xsl:param name="metadata.ibooks-specified-fonts" select="1"/>

  <xsl:param name="package.namespaces">
    <opf.foo/>
    <dc:foo/>
    <dcterms:foo/>
  </xsl:param>

  <!-- Param to specify whether or not to generate a separate HTML file for the cover -->
  <xsl:param name="generate.cover.html">
    <xsl:if test="//h:figure[@data-type='cover']//h:img[@src != '']">1</xsl:if>
  </xsl:param>

  <!-- Param to specify filename for cover HTML (only applicable if $generate.cover.html is enabled)-->
  <xsl:param name="cover.html.filename" select="'cover.html'"/>

  <!-- Param to specify whether or not to include the cover HTML file in the spine (only applicable if $generate.cover.html is enabled)-->
  <xsl:param name="cover.in.spine" select="1"/>

  <!-- Param to specify whether or not to generate an NCX TOC -->
  <xsl:param name="generate.ncx.toc" select="1"/>

  <!-- Filename to which to output the NCX TOC (if $generate.ncx.toc is enabled) -->
  <xsl:param name="ncx.toc.filename">toc.ncx</xsl:param>

  <!-- ID to use in the manifest for the NCX TOC (if $generate.ncx.toc is enabled) -->
  <xsl:param name="ncx.toc.id">toc.ncx</xsl:param>

  <!-- Specify how many levels of sections to include in NCX TOC. 
       An $ncx.toc.section.depth of 0 indicates only chapter-level headings and above to be included in NCX TOC
       An $ncx.toc.section depth of 1 indicates only sect1-level headings and above to be included in NCX TOC
       And so on...
    -->
  <xsl:param name="ncx.toc.section.depth" select="4"/>

  <!-- Include labels in NCX TOC? -->
  <xsl:param name="ncx.toc.include.labels" select="1"/>

  <!-- Include labels in Nav Doc TOC -->
  <xsl:param name="toc-include-labels" select="1"/>

  <!-- Include root chunk (index.html) in NCX? -->
  <!-- Don't turn this parameter on if you're not generating a root chunk -->
  <xsl:param name="ncx.include.root.chunk" select="$generate.root.chunk"/>

  <!-- Param to specify whether or not to include inline markup tagging (e.g., "em", "code") in generated XHTML TOC (EPUB Navigation Document) -->
  <xsl:param name="inline.markup.in.toc" select="0"/>

  <!-- Param to specify whether or not to include the Navigation Document (XHTML5 TOC) in the spine -->
  <xsl:param name="nav.in.spine" select="0"/>

  <!-- Param to specify whether or not to include the Navigation Document (XHTML5 TOC) in the NCX TOC -->
  <xsl:param name="nav.in.ncx" select="0"/>

  <!-- Filename for custom CSS to be embedded in EPUB; leave blank if none -->
  <xsl:param name="css.filename">epub.css</xsl:param>

  <!-- ID to use in the manifest for the CSS (if $css.filename is nonempty) -->
  <xsl:param name="css.id">epub-css</xsl:param>

  <!-- List "external assets" (assets not referenced in source, like fonts, CSS url()s)
       to be embedded here: place each asset on a separate line 
       Filenames should be relative paths from OPF directory to location of asset
  -->
  <xsl:param name="external.assets.list">DejaVuSerif.otf
DejaVuSans-Bold.otf
UbuntuMono-Regular.otf
UbuntuMono-Bold.otf
UbuntuMono-BoldItalic.otf
UbuntuMono-Italic.otf</xsl:param>

  <!-- Useful for EPUB 2 backward compatibility. Setting to 1 will turn on EPUB2-compatible elements, 
       which means that HTML5 structural semantic elements
       like <section> and <figure> will be replicated as <div> to help ensure compatibility for cross-referencing and CSS styling in
       non-EPUB3-compliant ereaders -->
  <xsl:param name="html4.structural.elements" select="1"/>

  <!-- Do default to turning on autolabeling for EPUB, as some older ereaders may not support the necessary CSS -->
  <xsl:param name="autogenerate.labels" select="1"/>

  <xsl:variable name="full.cover.filename">
    <xsl:value-of select="$outputdir"/>
    <xsl:if test="substring($outputdir, string-length($outputdir), 1) != '/'">
      <xsl:text>/</xsl:text>
    </xsl:if>
    <xsl:value-of select="$cover.html.filename"/>
  </xsl:variable>

  <xsl:template match="/">
    <xsl:call-template name="generate.mimetype"/>
    <xsl:call-template name="generate.meta-inf"/>
    <xsl:call-template name="generate.opf"/>
    <xsl:if test="$generate.ncx.toc = 1">
      <xsl:call-template name="generate.ncx.toc"/>
    </xsl:if>
    <xsl:if test="$generate.cover.html = 1">
      <xsl:call-template name="generate-cover-html"/>
    </xsl:if>
    <xsl:apply-imports/>
  </xsl:template>

  <!-- Output an HTML file for the book cover; override and customize as needed. Default output generally the same as epub3 docbook-xsl stylesheets -->
  <xsl:template name="generate-cover-html">
    <xsl:variable name="cover.html.content">
      <xsl:value-of select="'&lt;!DOCTYPE html&gt;'" disable-output-escaping="yes"/>
      <html xmlns:epub="http://www.idpf.org/2007/ops">
	<!-- ToDo: What else do we want in the <head>? -->
	<head>
	  <title>Cover</title>
	  <xsl:if test="$css.filename != ''">
	    <link rel="stylesheet" type="text/css" href="{$css.filename}" />
	  </xsl:if>
	</head>
	<body>
	  <xsl:copy-of select="//h:figure[@data-type='cover'][1]"/>
	</body>
      </html>
    </xsl:variable>
    <xsl:result-document href="{$full.cover.filename}" method="xml" encoding="UTF-8">
      <xsl:copy-of select="$cover.html.content"/>
      <xsl:fallback>
	<!-- <xsl:message>Falling back to XSLT 1.0 processor extension handling for generating result documents</xsl:message> -->
	<exsl:document href="{$full.cover.filename}" method="xml" encoding="UTF-8">
	  <xsl:copy-of select="exsl:node-set($cover.html.content)"/>
	</exsl:document>
      </xsl:fallback>
    </xsl:result-document>
  </xsl:template>

  <xsl:template match="@data-type" name="data-type">
    <xsl:param name="data-type-node" select="."/>
    <xsl:copy-of select="$data-type-node"/>
    <xsl:choose>
      <xsl:when test="$data-type-node = $valid.epub.type.values//e:epubtype">
	<xsl:attribute name="epub:type">
	  <xsl:value-of select="$data-type-node"/>
	</xsl:attribute>
      </xsl:when>
      <xsl:otherwise>
	<xsl:call-template name="log-message">
	  <xsl:with-param name="type" select="'DEBUG'"/>
	  <xsl:with-param name="message">
	    <xsl:text>Warning: @data-type value </xsl:text>
	    <xsl:value-of select="."/> 
	    <xsl:text> is not a valid epub:type value and no epub:type attribute will be added for it</xsl:text>
	  </xsl:with-param>
	</xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Overwrite write-chunk template to add epub namespace to root element -->
  <!-- ToDo: More elegant solution to parameterize namespace addition here? Better not to have to overwrite whole template -->
  <xsl:template name="write-chunk">
    <xsl:param name="output-filename"/>
    <xsl:variable name="full-output-filename">
      <xsl:call-template name="full-output-filename">
	<xsl:with-param name="output-filename" select="$output-filename"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:result-document href="{$full-output-filename}" method="xml" encoding="UTF-8">
      <xsl:call-template name="process-content-for-chunk"/>
      <xsl:fallback>
	<!-- <xsl:message>Falling back to XSLT 1.0 processor extension handling for generating result documents</xsl:message> -->
	<exsl:document href="{$full-output-filename}" method="xml" encoding="UTF-8">
	  <xsl:call-template name="process-content-for-chunk"/>
	</exsl:document>
      </xsl:fallback>
    </xsl:result-document>
  </xsl:template>

  <xsl:template name="process-content-for-chunk">
    <xsl:value-of select="'&lt;!DOCTYPE html&gt;'" disable-output-escaping="yes"/>
    <!-- Only add the <html>/<head> if they don't already exist -->
    <xsl:choose>
      <xsl:when test="not(self::h:html)">
	<html xmlns:epub="http://www.idpf.org/2007/ops">
	  <!-- ToDo: What else do we want in the <head>? -->
	  <head>
	    <title>
	      <xsl:variable name="title-markup">
		<xsl:apply-templates select="." mode="title.markup"/>
	      </xsl:variable>
	      <xsl:value-of select="$title-markup"/>
	      <xsl:if test="$title-markup = ''">
		<!-- For lack of alternative, fall back on local-name -->
		<!-- ToDo: Something better here? -->
		  <xsl:value-of select="local-name()"/>
	      </xsl:if>
	    </title>
	    <xsl:if test="$css.filename != ''">
	      <link rel="stylesheet" type="text/css" href="{$css.filename}" />
	    </xsl:if>
	  </head>
	  <xsl:choose>
	    <!-- Only add the body tag if doesn't already exist -->
	    <xsl:when test="not(self::h:body)">
	      <body data-type="book">
		<xsl:apply-imports/>
	      </body>
	    </xsl:when>
	    <xsl:otherwise>
	      <xsl:apply-imports/>
	    </xsl:otherwise>
	  </xsl:choose>
	</html>
	</xsl:when>
      <xsl:otherwise>
	<xsl:apply-imports/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
</xsl:stylesheet> 
