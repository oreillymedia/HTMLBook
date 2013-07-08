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
		xmlns:f="http://github.com/oreillymedia/HTMLBook/fonts"
		xmlns:h="http://www.w3.org/1999/xhtml"
		xmlns:htmlbook="https://github.com/oreillymedia/HTMLBook"
		xmlns:func="http://exslt.org/functions"
		xmlns="http://www.w3.org/1999/xhtml"
		extension-element-prefixes="exsl func set date"
		exclude-result-prefixes="exsl h func set date">

  <!-- Generate an EPUB from HTMLBook source. -->

  <!-- Imports chunk.xsl -->
  <xsl:import href="chunk.xsl"/>

  <!-- EPUB-specific parameters -->
  <xsl:param name="opf.namespace" select="'http://www.idpf.org/2007/opf'"/>

  <xsl:param name="metadata.unique-identifier">
    <!-- By default, try to pull from meta element in head -->
    <xsl:value-of select="//h:head/h:meta[contains(@name, 'identifier')][1]/@content"/>
  </xsl:param>

  <xsl:param name="opf.filename" select="'content.opf'"/>

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
  <xsl:param name="metadata.cover.id" select="'cover-image'"/>

  <xsl:parma name="metadata.cover.filename" select="//h:figure[@data-type = 'cover'][1]/h:img[1]/@src"/>

  <xsl:param name="metadata.ibooks-specified-fonts" select="1"/>

  <xsl:param name="package.namespaces">
    <opf.foo/>
    <dc:foo/>
    <dcterms:foo/>
  </xsl:param>

  <xsl:param name="generate.ncx.toc" select="1"/>

  <!-- Filename to which to output the NCX TOC (if $generate.ncx.toc is enabled) -->
  <xsl:param name="ncx.toc.filename">toc.ncx</xsl:param>

  <!-- ID to use in the manifest for the NCX TOC (if $generate.ncx.toc is enabled) -->
  <xsl:param name="ncx.toc.id">toc.ncx</xsl:param>

  <!-- Mimetype to use in the manifest for the NCX TOC (if $generate.ncx.toc is enabled) -->
  <xsl:param name="ncx.toc.mimetype">application/x-dtbncx+xml</xsl:param>

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
	<f:fonts>
	  <xsl:call-template name="get.fonts.xml">
	    <xsl:with-param name="fonts.to.process" select="$fonts.to.process"/>
	    <xsl:with-param name="first.call" select="0"/>
	  </xsl:call-template>
	</f:fonts>
      </xsl:when>
      <xsl:otherwise>
	<xsl:if test="normalize-space(substring-before($fonts.to.process, '&#x0A;')) != ''">
	  <xsl:variable name="font-filename">
	    <xsl:value-of select="normalize-space(substring-before($fonts.to.process, '&#x0A;'))"/>
	  </xsl:variable>
	  <xsl:message><xsl:value-of select="$font-filename"/></xsl:message>
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
	  <f:font filename="{$font-filename}" mimetype="{$font-mimetype}"/>
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

  <xsl:template name="generate.opf">
    <exsl:document href="{$outputdir}/{$opf.filename}" method="xml" encoding="UTF-8">
      <package namespace="{$opf.namespace}">
	<xsl:for-each select="exsl:node-set($package.namespaces)//*/namespace::*">
	  <xsl:copy-of select="."/>
	</xsl:for-each>
	<metadata>
	  <xsl:if test="$metadata.unique-identifier != ''">
	    <dc:identifier id="pub-identifier">
	      <xsl:value-of select="$metadata.unique-identifier"/>
	    </dc:identifier>
	  </xsl:if>
	  <dc:identifier id="pub-identifier">
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
	      <xsl:for-each select="$metadata.contributors">
		<xsl:value-of select="@content"/>
		<xsl:if test="count($metadata.contributors) &gt; 2 and position() != last()">, </xsl:if>
		<xsl:if test="(count($metadata.contributors) = 2 and position() != last()) or 
			      (count($metadata.contributors) &gt; 2 and (position() + 1 = position(last())))">and </xsl:if>
	      </xsl:for-each>
	    </dc:creator>
	    <xsl:for-each select="$metadata.contributors">
	      <meta property="dcterms:creator">
		<xsl:value-of select="@content"/>
	      </meta>
	    </xsl:for-each>
	  </xsl:if>
	  <xsl:if test="normalize-space($metadata.cover.filename) != ''">
	    <meta name="cover" content="{$metadata.cover.id}"/>
	  </xsl:if>
	  <xsl:if test="$metadata.ibooks-specified-fonts = 1">
	    <meta property="ibooks:specified-fonts">true</meta>
	  </xsl:if>
	</metadata>
	<manifest>
	  <!-- Add NCX TOC to EPUB manifest, if it will be included in the EPUB package -->
	  <xsl:if test="$generate.ncx.toc = 1">
	    <item id="{$ncx.toc.id}" href="{$outputdir}/{$ncx.toc.filename}" media-type="{$ncx.toc.mimetype}"/>
	  </xsl:if>
	  <!-- Add custom CSS to manifest, if present -->
	  <xsl:if test="$css.filename != ''">
	    <item id="{$css.id}" href="{$css.filename}" media-type="text/css"/>
	  </xsl:if>
	  <!-- Add any embedded fonts to EPUB manifest, if they will be included in the EPUB package -->
	  <xsl:for-each select="exsl:node-set($embedded.fonts.list.xml)//f:font">
	    <item id="{concat('epub.embedded.font.', position())}" href="{@filename}" media-type="{@mimetype}"/>
	  </xsl:for-each>
	  
	</manifest>
      </package>
    </exsl:document>
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
  
</xsl:stylesheet> 
