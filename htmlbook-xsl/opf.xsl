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

  <xsl:output method="xml"
              encoding="UTF-8"/>
  <xsl:preserve-space elements="*"/>

  <!-- Nodes by name -->
  <xsl:key name="nodes-by-name" match="*" use="local-name()"/>

  <xsl:variable name="full.opf.filename">
    <xsl:value-of select="$outputdir"/>
    <xsl:if test="substring($outputdir, string-length($outputdir), 1) != '/'">
      <xsl:text>/</xsl:text>
    </xsl:if>
    <xsl:value-of select="$opf.filename"/>
  </xsl:variable>
      
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
	<xsl:choose>
	  <xsl:when test="normalize-space(substring-before($fonts.to.process, '&#x0A;')) != ''">
	    <xsl:variable name="font-filename">
	      <xsl:value-of select="normalize-space(substring-before($fonts.to.process, '&#x0A;'))"/>
	    </xsl:variable>
	    <xsl:variable name="font-extension">
	      <xsl:value-of select="normalize-space(substring-after($font-filename, '.'))"/>
	    </xsl:variable>
	    <xsl:variable name="font-mimetype">
	      <xsl:call-template name="get-mimetype-from-file-extension">
		<xsl:with-param name="file-extension" select="$font-extension"/>
	      </xsl:call-template>
	    </xsl:variable>
	    <e:font filename="{$font-filename}" mimetype="{$font-mimetype}"/>
	    <xsl:if test="normalize-space(substring-after($fonts.to.process, '&#x0A;')) != ''">
	      <xsl:call-template name="get.fonts.xml">
		<xsl:with-param name="fonts.to.process" select="substring-after($fonts.to.process, '&#x0A;')"/>
		<xsl:with-param name="first.call" select="0"/>
	      </xsl:call-template>
	    </xsl:if>
	  </xsl:when>
	  <xsl:when test="normalize-space($fonts.to.process) != ''">
	    <xsl:variable name="font-filename">
	      <xsl:value-of select="normalize-space($fonts.to.process)"/>
	    </xsl:variable>
	    <xsl:variable name="font-extension">
	      <xsl:value-of select="normalize-space(substring-after($font-filename, '.'))"/>
	    </xsl:variable>
	    <xsl:variable name="font-mimetype">
	      <xsl:call-template name="get-mimetype-from-file-extension">
		<xsl:with-param name="file-extension" select="$font-extension"/>
	      </xsl:call-template>
	    </xsl:variable>
	    <e:font filename="{$font-filename}" mimetype="{$font-mimetype}"/>
	  </xsl:when>
	</xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="generate.mimetype">
    <!-- Outputs "mimetype" file that meets EPUB 3.0 specifications: http://www.idpf.org/epub/30/spec/epub30-ocf.html#physical-container-zip-->
    <!-- Override this template if you want to customize mimetype output -->
    <xsl:result-document href="mimetype" method="text">
      <xsl:fallback>
	<!-- <xsl:message>Falling back to XSLT 1.0 processor extension handling for generating result documents</xsl:message> -->
	<exsl:document href="mimetype" method="text">
	  <xsl:text>application/epub+zip</xsl:text>
	</exsl:document>
      </xsl:fallback>
      <xsl:text>application/epub+zip</xsl:text>
    </xsl:result-document>
  </xsl:template>

  <xsl:template name="generate.meta-inf">
    <!-- Outputs "META-INF" directory with container.xml file that meets EPUB 3.0 specifications: http://www.idpf.org/epub/30/spec/epub30-ocf.html#sec-container-metainf -->
    <!-- Override this template if you want to customize "META-INF" output (no support for multiple <rootfile> elements at this time) -->
    <xsl:variable name="container-xml">
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
    </xsl:variable>
    <xsl:result-document href="META-INF/container.xml" method="xml" encoding="UTF-8">
      <xsl:copy-of select="$container-xml"/>
      <xsl:fallback>
	<!-- <xsl:message>Falling back to XSLT 1.0 processor extension handling for generating result documents</xsl:message> -->
	<exsl:document href="META-INF/container.xml" method="xml" encoding="UTF-8">
	  <xsl:copy-of select="exsl:node-set($container-xml)"/>
	</exsl:document>
      </xsl:fallback>
    </xsl:result-document>
  </xsl:template>

  <xsl:template name="generate.opf">
    <xsl:result-document href="{$full.opf.filename}" method="xml" encoding="UTF-8">
      <xsl:call-template name="generate.opf.content"/>
      <xsl:fallback>
	<!-- <xsl:message>Falling back to XSLT 1.0 processor extension handling for generating result documents</xsl:message> -->
	<exsl:document href="{$full.opf.filename}" method="xml" encoding="UTF-8">
	  <xsl:call-template name="generate.opf.content"/>
	</exsl:document>
      </xsl:fallback>
    </xsl:result-document>
  </xsl:template>

  <xsl:template name="generate.opf.content">
    <xsl:param name="generate.guide" select="$generate.guide"/>
    <package version="3.0" unique-identifier="{$metadata.unique-identifier.id}">
      <xsl:if test="$metadata.ibooks-specified-fonts = 1">
	<xsl:attribute name="prefix">
	  <xsl:text>ibooks: http://vocabulary.itunes.apple.com/rdf/ibooks/vocabulary-extensions-1.0/</xsl:text>
	</xsl:attribute>
      </xsl:if>
      <xsl:for-each select="exsl:node-set($package.namespaces)//*/namespace::*">
	<xsl:copy-of select="."/>
      </xsl:for-each>
      <xsl:call-template name="opf.metadata"/>
      <xsl:call-template name="opf.manifest"/>
      <xsl:call-template name="generate-spine"/>
      <xsl:if test="$generate.guide = 1">
	<xsl:call-template name="generate-guide"/>
      </xsl:if>
    </package>
  </xsl:template>

  <xsl:template name="opf.manifest">
    <xsl:param name="generate.ncx.toc" select="$generate.ncx.toc"/>
    <xsl:param name="css.filename" select="$css.filename"/>
    <xsl:param name="generate.cover.html" select="$generate.cover.html"/>
    <xsl:param name="generate.root.chunk" select="$generate.root.chunk"/>
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
	<item id="{$css.id}" href="{$css.filename}">
	  <xsl:attribute name="media-type">
	    <xsl:call-template name="get-mimetype-from-file-extension">
	      <xsl:with-param name="file-extension" select="'css'"/>
	    </xsl:call-template>
	  </xsl:attribute>
	</item>
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
      </xsl:if>
      <!-- Add index page to manifest -->
      <xsl:if test="$generate.root.chunk = 1">
	<item>
	  <xsl:attribute name="id">
	    <xsl:apply-templates select="/*" mode="opf.id"/>
	  </xsl:attribute>
	  <xsl:attribute name="href">
	    <xsl:value-of select="$root.chunk.filename"/>
	  </xsl:attribute>
	  <xsl:attribute name="media-type">
	    <xsl:call-template name="get-mimetype-from-file-extension">
	      <xsl:with-param name="file-extension" select="'html'"/>
	    </xsl:call-template>
	  </xsl:attribute>
	</item>
      </xsl:if>
      <!-- Add images to manifest -->
      <xsl:call-template name="manifest-images"/>
      <!-- Add HTML documents to manifest -->
      <xsl:call-template name="manifest-html"/>
    </manifest>
  </xsl:template>

  <xsl:template name="opf.metadata">
    <xsl:param name="metadata.unique-identifier" select="$metadata.unique-identifier"/>
    <xsl:param name="metadata.unique-identifier.id" select="$metadata.unique-identifier.id"/>
    <xsl:param name="metadata.title" select="$metadata.title"/>
    <xsl:param name="metadata.language" select="$metadata.language"/>
    <xsl:param name="metadata.modified" select="$metadata.modified"/>
    <xsl:param name="metadata.rights" select="$metadata.rights"/>
    <xsl:param name="metadata.publisher" select="$metadata.publisher"/>
    <xsl:param name="metadata.subject" select="$metadata.subject"/>
    <xsl:param name="metadata.date" select="$metadata.date"/>
    <xsl:param name="metadata.description" select="$metadata.description"/>
    <xsl:param name="metadata.contributors" select="$metadata.contributors"/>
    <xsl:param name="metadata.creators" select="$metadata.creators"/>
    <xsl:param name="metadata.ibooks-specified-fonts" select="$metadata.ibooks-specified-fonts"/>
    <xsl:param name="generate.cover.html" select="$generate.cover.html"/>
    <metadata>
      <xsl:variable name="computed.identifier">
	<xsl:value-of select="$metadata.unique-identifier"/>
	<!-- If no identifier supplied, add a default value to ensure validity -->
	<xsl:if test="not($metadata.unique-identifier) or normalize-space($metadata.unique-identifier) = ''">
	  <xsl:value-of select="concat('randomid-', generate-id())"/>
	</xsl:if>
      </xsl:variable>

      <xsl:variable name="computed.title">
	<xsl:value-of select="$metadata.title"/>
	<!-- If no title supplied, add a default title to ensure validity -->
	<xsl:if test="not($metadata.title) or normalize-space($metadata.title) = ''">
	  <xsl:text>Untitled Book</xsl:text>
	</xsl:if>
      </xsl:variable>

      <xsl:variable name="computed.language">
	<xsl:value-of select="$metadata.language"/>
	<!-- If no title supplied, add a default language of 'en' to ensure validity -->
	<xsl:if test="not($metadata.language) or normalize-space($metadata.language) = ''">
	  <xsl:text>en</xsl:text>
	</xsl:if>
      </xsl:variable>

      <dc:identifier id="{$metadata.unique-identifier.id}">
	<xsl:value-of select="$computed.identifier"/>
      </dc:identifier>
      <meta id="meta-identifier" property="dcterms:identifier">
	<xsl:value-of select="$computed.identifier"/>
      </meta>
      <dc:title id="pub-title">
	<xsl:value-of select="$computed.title"/>
      </dc:title>
      <meta property="dcterms:title" id="meta-title">
	<xsl:value-of select="$computed.title"/>
      </meta>
      <dc:language id="pub-language">
	<xsl:value-of select="$computed.language"/>
      </dc:language>
      <meta property="dcterms:language" id="meta-language">
	<xsl:value-of select="$computed.language"/>
      </meta>
      <meta property="dcterms:modified">
	<!-- If no modified date supplied, add a default date to ensure validity -->
	<xsl:value-of select="$metadata.modified"/>
	<xsl:if test="not($metadata.modified) or normalize-space($metadata.modified) = ''">
	  <xsl:text>2014-01-01</xsl:text>
	</xsl:if>
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
      <xsl:if test="$generate.cover.html = 1">
	<meta name="cover" content="{$epub.cover.image.id}"/>
      </xsl:if>
      <xsl:if test="$metadata.ibooks-specified-fonts = 1">
	<meta property="ibooks:specified-fonts">true</meta>
      </xsl:if>
    </metadata>
  </xsl:template>

  <xsl:template name="generate-spine">
    <xsl:param name="chunk.nodes" select="key('chunks', 1)"/>
    <xsl:param name="generate.ncx.toc" select="$generate.ncx.toc"/>
    <xsl:param name="cover.in.spine" select="$cover.in.spine"/>
    <xsl:param name="generate.cover.html" select="$generate.cover.html"/>
    <spine>
      <xsl:if test="$generate.ncx.toc = 1">
	<xsl:attribute name="toc">
	  <xsl:value-of select="$ncx.toc.id"/>
	</xsl:attribute>
      </xsl:if>
      <xsl:if test="$cover.in.spine = 1 and $generate.cover.html = 1">
	<itemref idref="{$epub.cover.html.id}"/>
      </xsl:if>
      <xsl:if test="$generate.root.chunk = 1">
	<!-- Put root chunk in spine -->
	<itemref>
	  <xsl:attribute name="idref">
	    <xsl:apply-templates select="/*" mode="opf.id"/>
	  </xsl:attribute>
	</itemref>
      </xsl:if>
      <xsl:for-each select="$chunk.nodes">
	<xsl:apply-templates select="." mode="opf.spine.itemref"/>
      </xsl:for-each>
    </spine>
  </xsl:template>

  <xsl:template name="generate-guide">
    <xsl:param name="generate.cover.html" select="$generate.cover.html"/>
    <xsl:param name="html5.toc.node" select="//h:body/h:nav[@data-type='toc' and not(preceding::h:nav[@data-type='toc'])][1]"/>
    <guide>
      <!-- Generating <reference> elements for cover, TOC, and start of text -->
      <!-- Override and customize as appropriate, if desired -->

      <!-- Generate cover <reference> if there is a cover HTML file -->
      <xsl:if test="$generate.cover.html = 1">
	<reference href="{$cover.html.filename}" type="cover" title="Cover"/>
      </xsl:if>

      <!-- Generate reference to HTML5 TOC (EPUB Nav Doc) if present (and it should be!)-->
      <xsl:if test="$html5.toc.node">
	<xsl:variable name="html5-toc-filename">
	  <xsl:call-template name="output-filename-for-chunk">
	    <xsl:with-param name="node" select="$html5.toc.node"/>
	  </xsl:call-template>
	</xsl:variable>
	<reference href="{$html5-toc-filename}" type="toc" title="Table of Contents"/>
      </xsl:if>
      
      <!-- Calculate <reference element for start-of-text -->
      <!-- Override and customize for different handling, if desired -->
      <xsl:variable name="start-of-text-filename">
	<xsl:choose>
	  <!-- If there's a titlepage, use that as start-of-text -->
	  <xsl:when test="//h:body/h:section[@data-type='titlepage']">
	    <xsl:call-template name="output-filename-for-chunk">
	      <xsl:with-param name="node" select="//h:body/h:section[@data-type='titlepage'][1]"/>
	    </xsl:call-template>
	  </xsl:when>
	  <!-- Otherwise, if there's a cover, use that as start-of-text -->
	  <xsl:when test="$generate.cover.html = 1">
	    <xsl:value-of select="$cover.html.filename"/>
	  </xsl:when>
	  <!-- Otherwise, just use the first <section> in the text -->
	  <xsl:otherwise>
	    <xsl:call-template name="output-filename-for-chunk">
	      <xsl:with-param name="node" select="//h:section[1]"/>
	    </xsl:call-template>
	  </xsl:otherwise>
	</xsl:choose>
      </xsl:variable>
      <reference href="{$start-of-text-filename}" type="text"/>      
    </guide>
  </xsl:template>

  <xsl:template match="*" mode="opf.spine.itemref">
    <itemref>
      <xsl:attribute name="idref">
	<xsl:apply-templates select="." mode="opf.id"/>
      </xsl:attribute>
    </itemref>
  </xsl:template>

  <xsl:template match="h:nav[@data-type='toc']" mode="opf.spine.itemref">
    <xsl:param name="nav.in.spine" select="$nav.in.spine"/>
    <xsl:if test="$nav.in.spine = 1">
      <itemref>
	<xsl:attribute name="idref">
	  <xsl:apply-templates select="." mode="opf.id"/>
	</xsl:attribute>
      </itemref>
    </xsl:if>
  </xsl:template>

  <xsl:template name="manifest-images">
    <xsl:param name="img-nodes" select="key('nodes-by-name', 'img')"/>
    <xsl:for-each select="$img-nodes">
      <!-- Generate an <item> for this img only if it is the first image with this @src attribute -->
      <xsl:if test="not(@src = (preceding::h:img/@src|ancestor::h:img/@src))">
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
      </xsl:if>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="manifest-html">
    <xsl:param name="chunk.nodes" select="key('chunks', 1)"/>
    <xsl:for-each select="$chunk.nodes">
      <item>
	<xsl:attribute name="id">
	  <xsl:apply-templates select="." mode="opf.id"/>
	</xsl:attribute>
	<xsl:variable name="output-filename">
	  <xsl:call-template name="output-filename-for-chunk"/>
	</xsl:variable>
	<xsl:attribute name="href">
	  <xsl:value-of select="$output-filename"/>
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
	<xsl:when test="ancestor::*[htmlbook:is-chunk(., $chunk.level) = 1 and not(descendant::*[htmlbook:is-chunk(., $chunk.level) = 1][descendant::*[generate-id() = generate-id($element-descendants[1])]])][generate-id() = $chunk-id]">
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
