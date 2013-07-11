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
		xmlns:h="http://www.w3.org/1999/xhtml"
		xmlns:htmlbook="https://github.com/oreillymedia/HTMLBook"
		xmlns:func="http://exslt.org/functions"
		xmlns="http://www.idpf.org/2007/opf"
		extension-element-prefixes="exsl func set date"
		exclude-result-prefixes="date e exsl func h htmlbook m ncx opf set svg">

  <!-- Generate an EPUB from HTMLBook source. -->
  <!-- ToDo: Logic for generating cover.html -->
  <!-- ToDo: Refactor MathML/SVG in chunk logic as an exslt function? -->
  <!-- ToDo: Support for adding the "scripted" property in the manifest to content that contains JS -->
  <!-- ToDo: Convert @data-type to @epub:type -->
  <!-- ToDo: Logic to relativize absolute image filerefs for EPUB package? -->
  <!-- ToDo: Logic to copy over images and zip EPUB via extension -->
  <!-- ToDo: Generate NCX TOC -->

  <!-- Imports chunk.xsl -->
  <xsl:import href="chunk.xsl"/>

  <!-- Nodes by name -->
  <xsl:key name="nodes-by-name" match="*" use="local-name()"/>

  <!-- EPUB-specific parameters -->
  <xsl:param name="opf.namespace" select="'http://www.idpf.org/2007/opf'"/>

  <!-- mimetype mapping; feel free to modify existing mapping or point to different mapping document -->
  <xsl:param name="mimetypes-by-file-extension-mapping" select="document('mimetypes-by-file-extension.xml')"/>

  <xsl:param name="metadata.unique-identifier">
    <!-- By default, try to pull from meta element in head -->
    <xsl:value-of select="//h:head/h:meta[contains(@name, 'identifier')][1]/@content"/>
  </xsl:param>

  <!-- ID to use on the dc:identifier element corresponding to the EPUB unique identifier -->
  <xsl:param name="metadata.unique-identifier.id" select="'pub-identifier'"/>

  <xsl:param name="opf.filename" select="'content.opf'"/>

  <xsl:variable name="full.opf.filename">
    <xsl:call-template name="full-output-filename">
      <xsl:with-param name="output-filename" select="$opf.filename"/>
    </xsl:call-template>
  </xsl:variable>

  <!-- Outputdir is the main content dir -->
  <xsl:param name="outputdir" select="'OEBPS'"/>

  <xsl:param name="metadata.title">
    <xsl:value-of select="//h:body/h:h1[1]"/>
  </xsl:param>

  <xsl:param name="metadata.language">
    <xsl:value-of select="$book-language"/>
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
	<xsl:message terminate="yes">
          <xsl:text>ERROR: no last-modified date value could be determined, </xsl:text>
          <xsl:text>so cannot output required meta element with </xsl:text>
          <xsl:text>dcterms:modified attribute. Exiting.</xsl:text>
	</xsl:message>
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

  <xsl:param name="metadata.creators" select="//h:head/h:meta[contains(@name, 'creator')]"/>

  <!-- Id to use to reference cover image -->
  <xsl:param name="epub.cover.image.id" select="'cover-image'"/>

  <!-- ID to use to reference cover filename -->
  <xsl:param name="epub.cover.html.id" select="'cover'"/>

  <xsl:param name="metadata.cover.filename" select="//h:figure[@data-type = 'cover'][1]/h:img[1]/@src"/>

  <xsl:param name="metadata.ibooks-specified-fonts" select="1"/>

  <xsl:param name="package.namespaces">
    <opf.foo/>
    <dc:foo/>
    <dcterms:foo/>
  </xsl:param>

  <!-- Param to specify whether or not to generate a separate HTML file for the cover -->
  <xsl:param name="generate.cover.html" select="1"/>

  <!-- Param to specify filename for cover HTML (only applicable if $generate.cover.html is enabled)-->
  <xsl:param name="cover.html.filename" select="'cover.html'"/>

  <!-- Param to specify whether or not to include the cover HTML file in the spine (only applicable if $generate.cover.html is enabled)-->
  <xsl:param name="cover.in.spine" select="1"/>

  <!-- Param to specify whether or not to include the Navigation Document (XHTML5 TOC) in the spine -->
  <xsl:param name="nav.in.spine" select="1"/>

  <xsl:param name="generate.ncx.toc" select="1"/>

  <!-- Filename to which to output the NCX TOC (if $generate.ncx.toc is enabled) -->
  <xsl:param name="ncx.toc.filename">toc.ncx</xsl:param>

  <!-- ID to use in the manifest for the NCX TOC (if $generate.ncx.toc is enabled) -->
  <xsl:param name="ncx.toc.id">toc.ncx</xsl:param>

  <!-- Filename for custom CSS to be embedded in EPUB; leave blank if none -->
  <xsl:param name="css.filename">epub.css</xsl:param>

  <!-- ID to use in the manifest for the CSS (if $css.filename is nonempty) -->
  <xsl:param name="css.id">epub-css</xsl:param>

  <!-- List fonts to be embedded here: place each font on a separate line -->
  <xsl:param name="embedded.fonts.list">DejaVuSerif.otf
DejaVuSans-Bold.otf
UbuntuMono-Regular.otf
UbuntuMono-Bold.otf
UbuntuMono-BoldItalic.otf
UbuntuMono-Italic.otf
</xsl:param>
      
  <!-- Convert $embedded.fonts.list to XML for easier parsing -->
  <xsl:variable name="embedded.fonts.list.xml">
    <xsl:call-template name="get.fonts.xml"/>
  </xsl:variable>

  <!-- Reformat fonts list as XML that can be parsed -->
  <xsl:template name="get.fonts.xml">
    <xsl:param name="fonts.to.process" select="$embedded.fonts.list"/>
    <xsl:param name="first.call" select="1"/>
    <xsl:choose>
      <xsl:when test="$first.call = 1">
	<e:fonts>
	  <xsl:call-template name="get.fonts.xml">
	    <xsl:with-param name="fonts.to.process" select="$fonts.to.process"/>
	    <xsl:with-param name="first.call" select="0"/>
	  </xsl:call-template>
	</e:fonts>
      </xsl:when>
      <xsl:otherwise>
	<xsl:if test="normalize-space(substring-before($fonts.to.process, '&#x0A;')) != ''">
	  <xsl:variable name="font-filename">
	    <xsl:value-of select="normalize-space(substring-before($fonts.to.process, '&#x0A;'))"/>
	  </xsl:variable>
	  <xsl:variable name="font-extension">
	    <xsl:value-of select="normalize-space(substring-after($font-filename, '.'))"/>
	  </xsl:variable>
	  <xsl:variable name="font-mimetype">
	    <xsl:choose>
	      <xsl:when test="$font-extension = 'otf'">application/vnd.ms-opentype</xsl:when>
	      <xsl:when test="$font-extension = 'ttf'">font/truetype</xsl:when>
	      <!-- Default to opentype font -->
	      <xsl:otherwise>application/vnd.ms-opentype</xsl:otherwise>
	    </xsl:choose>
	  </xsl:variable>
	  <e:font filename="{$font-filename}" mimetype="{$font-mimetype}"/>
	  <xsl:if test="normalize-space(substring-after($fonts.to.process, '&#x0A;')) != ''">
	    <xsl:call-template name="get.fonts.xml">
	      <xsl:with-param name="fonts.to.process" select="substring-after($fonts.to.process, '&#x0A;')"/>
	      <xsl:with-param name="first.call" select="0"/>
	    </xsl:call-template>
	  </xsl:if>
	</xsl:if>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Directory to place embedded fonts, relative to content directory; leave blank to put in root content dir (e.g., in "OEBPS" dir) -->
  <xsl:param name="embedded.fonts.directory"/>

  <xsl:output method="xml"
              encoding="UTF-8"/>
  <xsl:preserve-space elements="*"/>

  <xsl:template match="/">
    <xsl:call-template name="generate.opf"/>
    <xsl:call-template name="generate.mimetype"/>
    <xsl:call-template name="generate.meta-inf"/>
    <xsl:apply-imports/>
  </xsl:template>

  <xsl:template name="generate.mimetype">
    <!-- Outputs "mimetype" file that meets EPUB 3.0 specifications: http://www.idpf.org/epub/30/spec/epub30-ocf.html#physical-container-zip-->
    <!-- Override this template if you want to customize mimetype output -->
    <exsl:document href="mimetype" method="text">
      <xsl:text>application/epub+zip</xsl:text>
    </exsl:document>
  </xsl:template>

  <xsl:template name="generate.meta-inf">
    <!-- Outputs "META-INF" directory with container.xml file that meets EPUB 3.0 specifications: http://www.idpf.org/epub/30/spec/epub30-ocf.html#sec-container-metainf -->
    <!-- Override this template if you want to customize "META-INF" output (no support for multiple <rootfile> elements at this time) -->
    <exsl:document href="META-INF/container.xml" method="xml" encoding="UTF-8">
      <container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
	<rootfiles>
	  <rootfile>
	    <xsl:attribute name="full-path">
	      <xsl:value-of select="$full.opf.filename"/>
	    </xsl:attribute>
	    <xsl:attribute name="media-type">
	      <xsl:call-template name="get-mimetype-from-file-extension">
		<xsl:with-param name="file-extension" select="'opf'"/>
	      </xsl:call-template>
	    </xsl:attribute>
	  </rootfile>
	</rootfiles>
      </container>
    </exsl:document>
  </xsl:template>

  <xsl:template name="generate.opf">
    <exsl:document href="{$full.opf.filename}" method="xml" encoding="UTF-8">
      <package version="3.0" unique-identifier="{$metadata.unique-identifier.id}">
	<xsl:if test="$metadata.ibooks-specified-fonts = 1">
	  <xsl:attribute name="prefix">
	    <xsl:text>ibooks: http://vocabulary.itunes.apple.com/rdf/ibooks/vocabulary-extensions-1.0/</xsl:text>
	  </xsl:attribute>
	</xsl:if>
	<xsl:for-each select="exsl:node-set($package.namespaces)//*/namespace::*">
	  <xsl:copy-of select="."/>
	</xsl:for-each>
	<metadata>
	  <dc:identifier id="{$metadata.unique-identifier.id}">
	    <xsl:value-of select="$metadata.unique-identifier"/>
	  </dc:identifier>
	  <meta id="meta-identifier" property="dcterms:identifier">
	    <xsl:value-of select="$metadata.unique-identifier"/>
	  </meta>
	  <dc:title id="pub-title">
	    <xsl:value-of select="$metadata.title"/>
	  </dc:title>
	  <meta property="dcterms:title" id="meta-title">
	    <xsl:value-of select="$metadata.title"/>
	  </meta>
	  <dc:language id="pub-language">
	    <xsl:value-of select="$metadata.language"/>
	  </dc:language>
	  <meta property="dcterms:language" id="meta-language">
	    <xsl:value-of select="$metadata.language"/>
	  </meta>
	  <meta property="dcterms:modified">
	    <xsl:value-of select="$metadata.modified"/>
	  </meta>
	  <xsl:if test="$metadata.rights != ''">
	    <dc:rights>
	      <xsl:value-of select="$metadata.rights"/>
	    </dc:rights>
	    <meta property="dcterms:rightsHolder">
	      <xsl:value-of select="$metadata.rights"/>
	    </meta>
	  </xsl:if>
	  <xsl:if test="$metadata.publisher != ''">
	    <dc:publisher>
	      <xsl:value-of select="$metadata.publisher"/>
	    </dc:publisher>
	    <meta property="dcterms:publisher">
	      <xsl:value-of select="$metadata.publisher"/>
	    </meta>
	  </xsl:if>
	  <xsl:if test="$metadata.subject != ''">
	    <dc:subject>
	      <xsl:value-of select="$metadata.subject"/>
	    </dc:subject>
	    <meta property="dcterms:subject">
	      <xsl:value-of select="$metadata.subject"/>
	    </meta>
	  </xsl:if>
	  <xsl:if test="$metadata.date != ''">
	    <dc:date>
	      <xsl:value-of select="$metadata.date"/>
	    </dc:date>
	    <meta property="dcterms:date">
	      <xsl:value-of select="$metadata.date"/>
	    </meta>
	  </xsl:if>
	  <xsl:if test="$metadata.description != ''">
	    <dc:description>
	      <xsl:value-of select="$metadata.description"/>
	    </dc:description>
	    <meta property="dcterms:description">
	      <xsl:value-of select="$metadata.description"/>
	    </meta>
	  </xsl:if>
	  <xsl:if test="count($metadata.contributors) &gt; 0">
	    <xsl:for-each select="$metadata.contributors">
	      <dc:contributor>
		<xsl:value-of select="@content"/>
	      </dc:contributor>
	      <meta property="dcterms:contributor">
		<xsl:value-of select="@content"/>
	      </meta>
	    </xsl:for-each>
	  </xsl:if>
	  <xsl:if test="count($metadata.creators) &gt; 0">
	    <!-- Use just one dc:creator element for all authors, as that sadly gives better results in ereaders -->
	    <dc:creator>	      
	      <xsl:for-each select="$metadata.creators">
		<xsl:if test="count($metadata.creators) &gt; 2 and position() != 1">
		  <xsl:call-template name="get-localization-value">
		    <xsl:with-param name="gentext-key" select="'listcomma'"/>
		  </xsl:call-template>
		</xsl:if>
		<xsl:if test="count($metadata.creators) &gt; 1 and position() != 1">
		  <xsl:text> </xsl:text>
		</xsl:if>
		<xsl:if test="count($metadata.creators) &gt; 1 and position() = last()">
		  <xsl:call-template name="get-localization-value">
		    <xsl:with-param name="gentext-key" select="'and'"/>
		  </xsl:call-template>
		  <xsl:text> </xsl:text>
		</xsl:if>
		<xsl:value-of select="@content"/>
	      </xsl:for-each>
	    </dc:creator>
	    <xsl:for-each select="$metadata.creators">
	      <meta property="dcterms:creator">
		<xsl:value-of select="@content"/>
	      </meta>
	    </xsl:for-each>
	  </xsl:if>
	  <xsl:if test="normalize-space($metadata.cover.filename) != ''">
	    <meta name="cover" content="{$epub.cover.image.id}"/>
	  </xsl:if>
	  <xsl:if test="$metadata.ibooks-specified-fonts = 1">
	    <meta property="ibooks:specified-fonts">true</meta>
	  </xsl:if>
	</metadata>
	<manifest>
	  <!-- Add NCX TOC to EPUB manifest, if it will be included in the EPUB package -->
	  <xsl:if test="$generate.ncx.toc = 1">
	    <item id="{$ncx.toc.id}" href="{$ncx.toc.filename}">
	      <xsl:attribute name="media-type">
		<xsl:call-template name="get-mimetype-from-file-extension">
		  <xsl:with-param name="file-extension" select="'ncx'"/>
		</xsl:call-template>
	      </xsl:attribute>
	    </item>
	  </xsl:if>
	  <!-- Add custom CSS to manifest, if present -->
	  <xsl:if test="$css.filename != ''">
	    <item id="{$css.id}" href="{$css.filename}" media-type="text/css"/>
	  </xsl:if>
	  <!-- Add any embedded fonts to EPUB manifest, if they will be included in the EPUB package -->
	  <xsl:for-each select="exsl:node-set($embedded.fonts.list.xml)//e:font">
	    <item id="{concat('epub.embedded.font.', position())}" href="{@filename}" media-type="{@mimetype}"/>
	  </xsl:for-each>
	  <!-- Add cover to manifest, if present -->
	  <xsl:if test="$generate.cover.html = 1">
	    <item>
	      <xsl:attribute name="id">
		<xsl:value-of select="$epub.cover.html.id"/>
	      </xsl:attribute>
	      <xsl:attribute name="href">
		<xsl:value-of select="$cover.html.filename"/>
	      </xsl:attribute>
	      <xsl:attribute name="media-type">
		<xsl:call-template name="get-mimetype-from-file-extension">
		  <xsl:with-param name="file-extension" select="'html'"/>
		</xsl:call-template>
	      </xsl:attribute>
	    </item>
	  <!-- Add images to manifest -->
	  <xsl:call-template name="manifest-images"/>
	  <!-- Add HTML documents to manifest -->
	  <xsl:call-template name="manifest-html"/>
	  </xsl:if>
	</manifest>
	<xsl:call-template name="generate-spine"/>
      </package>
    </exsl:document>
  </xsl:template>

  <xsl:template name="generate-spine">
    <spine>
      <xsl:if test="$cover.in.spine = 1">
	<itemref idref="{$epub.cover.html.id}"/>
      </xsl:if>
      <xsl:for-each select="key('chunks', 1)">
	<xsl:apply-templates select="." mode="opf.spine.itemref"/>
      </xsl:for-each>
    </spine>
  </xsl:template>

  <xsl:template match="*" mode="opf.spine.itemref">
    <itemref>
      <xsl:attribute name="idref">
	<xsl:apply-templates select="." mode="opf.id"/>
      </xsl:attribute>
    </itemref>
  </xsl:template>

  <xsl:template match="h:nav[@data-type='toc']">
    <xsl:if test="$nav.in.spine = 1">
      <itemref>
	<xsl:attribute name="idref">
	  <xsl:apply-templates select="." mode="opf.id"/>
	</xsl:attribute>
      </itemref>
    </xsl:if>
  </xsl:template>

  <xsl:template name="manifest-images">
    <xsl:for-each select="key('nodes-by-name', 'img')">
      <xsl:variable name="filename" select="@src"/>
      <xsl:variable name="file-extension">
	<xsl:call-template name="get-extension-from-filename">
	  <xsl:with-param name="filename" select="$filename"/>
	</xsl:call-template>
      </xsl:variable>
      <xsl:variable name="file-mimetype">
	<xsl:call-template name="get-mimetype-from-file-extension">
	  <xsl:with-param name="file-extension" select="$file-extension"/>
	</xsl:call-template>
      </xsl:variable>
      <item>
	<xsl:choose>
	  <xsl:when test="ancestor::h:figure[@data-type='cover']">
	    <!-- Custom id and properties values if we're doing the manifest <item> for the cover image -->
	    <xsl:attribute name="id">
	      <xsl:value-of select="$epub.cover.image.id"/>
	    </xsl:attribute>
	    <xsl:attribute name="properties">cover-image</xsl:attribute>
	  </xsl:when>
	  <xsl:otherwise>
	    <xsl:attribute name="id">
	      <xsl:apply-templates select="." mode="opf.id"/>
	    </xsl:attribute>
	  </xsl:otherwise>
	</xsl:choose>
	<xsl:attribute name="href">
	  <xsl:value-of select="$filename"/>
	</xsl:attribute>
	<xsl:attribute name="media-type">
	  <xsl:value-of select="$file-mimetype"/>
	</xsl:attribute>
      </item>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="manifest-html">
    <xsl:for-each select="key('chunks', 1)">
      <item>
	<xsl:attribute name="id">
	  <xsl:apply-templates select="." mode="opf.id"/>
	</xsl:attribute>
	<xsl:variable name="output-filename">
	  <xsl:call-template name="output-filename-for-chunk"/>
	</xsl:variable>
	<xsl:variable name="full-output-filename">
	  <xsl:call-template name="full-output-filename">
	    <xsl:with-param name="output-filename" select="$output-filename"/>
	  </xsl:call-template>
	</xsl:variable>
	<xsl:attribute name="href">
	  <xsl:value-of select="$full-output-filename"/>
	</xsl:attribute>
	<xsl:attribute name="media-type">
	  <xsl:call-template name="get-mimetype-from-file-extension">
	    <xsl:with-param name="file-extension" select="'html'"/>
	  </xsl:call-template>
	</xsl:attribute>
	<xsl:variable name="properties">
	  <xsl:apply-templates select="." mode="opf.manifest.properties"/>
	</xsl:variable>
	<xsl:if test="$properties != ''">
	  <xsl:attribute name="properties">
	    <xsl:value-of select="$properties"/>
	  </xsl:attribute>
	</xsl:if>
      </item>
    </xsl:for-each>
  </xsl:template>

  <xsl:template match="*" mode="opf.id">
    <xsl:variable name="id-prefix">
      <xsl:choose>
	<xsl:when test="@data-type">
	  <xsl:value-of select="@data-type"/>
	</xsl:when>
	<xsl:otherwise>
	  <xsl:value-of select="local-name()"/>
	</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:value-of select="concat($id-prefix, '-',  generate-id())"/>
  </xsl:template>

  <xsl:template match="h:nav[@data-type='toc' and not(preceding::h:nav[@data-type='toc'])]" mode="opf.manifest.properties">
    <xsl:text>nav</xsl:text>
  </xsl:template>

  <xsl:template match="*" mode="opf.manifest.properties">
    <!-- Check to see if the chunk contains either MathML or SVG content, which requires additional properties to be specified -->
    <xsl:variable name="mathml-in-chunk">
      <xsl:call-template name="has-element-in-chunk">
	<xsl:with-param name="element-name" select="'math'"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="svg-in-chunk">
      <xsl:call-template name="has-element-in-chunk">
	<xsl:with-param name="element-name" select="'svg'"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="properties-list">
      <xsl:if test="$mathml-in-chunk = 1">
	<xsl:text> mathml</xsl:text>
      </xsl:if>
      <xsl:if test="$svg-in-chunk = 1">
	<xsl:text> svg</xsl:text>
      </xsl:if>
    </xsl:variable>
    <xsl:value-of select="normalize-space($properties-list)"/>
  </xsl:template>

  <xsl:template name="has-element-in-chunk">
    <xsl:param name="element-name"/>
    <xsl:param name="chunk" select="."/>
    <xsl:param name="chunk-id" select="generate-id()"/>
    <!-- Yes, we're using local-name() here and ignoring namespace prefix, because name() appears not to work consistently and local-name() is good enough -->
    <xsl:param name="element-descendants" select="$chunk//*[local-name() = $element-name]"/>
    <xsl:for-each select="$element-descendants[1]">
      <xsl:choose>
	<!-- Check if the element's nearest chunk ancestor is the chunk in question... -->
	<xsl:when test="ancestor::*[htmlbook:is-chunk(.) = 1 and not(descendant::*[htmlbook:is-chunk(.) = 1][descendant::*[generate-id() = generate-id($element-descendants[1])]])][generate-id() = $chunk-id]">
	  <!--...It is: We have $element-name in this chunk! -->
	  <xsl:text>1</xsl:text>
	</xsl:when>
	<xsl:otherwise>
	  <!--...It's not. Recurse to test the rest of element descendants to see if they're in the chunk in question -->
	  <xsl:if test="count($element-descendants) &gt; 1">
	    <xsl:call-template name="has-element-in-chunk">
	      <xsl:with-param name="chunk" select="$chunk"/>
	      <xsl:with-param name="chunk-id" select="$chunk-id"/>
	      <xsl:with-param name="element-descendants" select="$element-descendants[not(position() = 1)]"/>
	    </xsl:call-template>
	  </xsl:if>
	</xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>
  </xsl:template>

  <!-- borrowed from docbook-xsl epub3/epub3-element-mods.xsl -->
  <xsl:template name="convert.date.to.utc">
    <xsl:param name="date" select="''"/>
    <!-- input format is YYYY-MM-DDTHH:MM:SS-X:00                                                                                                                                     
	 where -X:00 is the offset from UTC. -->
    
    <!-- output format is YYYY-MM-DDTHH:MM:SSZ with no offset -->
    <!-- FIX ME:  Not so easy without a proper UTC date function. -->
    <!-- Currently it just converts the local time to this format, which is                                                                                                           
	 not the correct UTC time. -->
    <xsl:value-of select="concat(substring($date,1,19), 'Z')"/>
  </xsl:template>

  <xsl:template name="get-extension-from-filename">
    <xsl:param name="filename"/>
    <xsl:choose>
      <!-- No extension :( -->
      <xsl:when test="not(contains($filename, '.'))"/>
      <!-- Just one dot in filename; extension is whatever's after it -->
      <xsl:when test="not(contains(substring-after($filename, '.'), '.'))">
	<xsl:value-of select="substring-after($filename, '.')"/>
      </xsl:when>
      <xsl:otherwise>
	<!-- Multiple dots; recurse to get last one -->
	<xsl:call-template name="get-extension-from-filename">
	  <xsl:with-param name="filename" select="substring-after($filename, '.')"/>
	</xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="get-mimetype-from-file-extension">
    <xsl:param name="file-extension"/>
    <xsl:variable name="normalized-file-extension" select="normalize-space(translate($file-extension, $uppercase, $lowercase))"/>
    <xsl:choose>
      <xsl:when test="$mimetypes-by-file-extension-mapping//e:mimetype[@file-extension = $normalized-file-extension]">
	<xsl:value-of select="$mimetypes-by-file-extension-mapping//e:mimetype[@file-extension = $normalized-file-extension][1]"/>
      </xsl:when>
      <xsl:otherwise>
	<!-- No mimetype match found? Default to HTML mimetype :( -->
	<xsl:text>application/xhtml+xml</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
</xsl:stylesheet> 
