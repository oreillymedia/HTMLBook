<xsl:stylesheet version="1.0"
		xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns:exsl="http://exslt.org/common"
		xmlns:h="http://www.w3.org/1999/xhtml"
		xmlns:htmlbook="https://github.com/oreillymedia/HTMLBook"
		xmlns:func="http://exslt.org/functions"
		xmlns="http://www.w3.org/1999/xhtml"
		extension-element-prefixes="exsl func"
		exclude-result-prefixes="exsl h func">

  <!-- Chunk template used to split content among multiple .html files -->

  <!-- ToDo: Refactor to eliminate duplicate code around href generation for XREF vs. non-XREF <a> elems -->

  <!-- ToDo: Add "previous" and "next" links as in the docbook-xsl stylesheets? -->

  <!-- Imports htmlbook.xsl -->
  <xsl:import href="htmlbook.xsl"/>

  <xsl:output method="xml"
              encoding="UTF-8"/>
  <xsl:preserve-space elements="*"/>

  <xsl:key name="chunks" match="h:section|h:div[@data-type='part']|h:nav[@data-type='toc']" use="htmlbook:is-chunk(.)"/>

  <!-- Nodeset of all chunks in this document -->
  <xsl:variable name="chunks" select="key('chunks', '1')"/> <!-- All chunks have an is-chunk() value of 1 -->

  <!-- Specify whether to generate a root chunk -->
  <xsl:param name="generate.root.chunk" select="0"/>

  <!-- Specify the filename for the root chunk, if $generate.root.chunk is enabled -->
  <xsl:param name="root.chunk.filename" select="'index.html'"/>

  <!-- Specify a prefix for output filename for a given data-type -->
  <xsl:param name="output.filename.prefix.by.data-type">
appendix:app
chapter:ch
index:ix
part:part
sect1:s
sect2:s
sect3:s
sect4:s
sect5:s
  </xsl:param>

  <!-- Specify an output directory for chunked files; otherwise defaults to current directory -->
  <xsl:param name="outputdir"/>

  <!-- By default for chunked output, turn on footnote processing into separate marker/hyperlink and footnote content -->
  <xsl:param name="process.footnotes" select="1"/>

  <!-- Specify filename containing a custom "wrapper" for chunked content (expectation is that it will contain <html>, <head>, and <body> elements -->
  <!-- Use the PI <?yield?> in the location in which the HTML chunk content should be inserted -->
  <xsl:param name="custom.chunk.wrapper"/>

  <xsl:template match="/h:html">
    <xsl:apply-templates select="h:body"/>
  </xsl:template>

  <!-- Logic for root chunk -->
  <xsl:template match="h:body">
    <xsl:choose>
      <xsl:when test="$generate.root.chunk = 1">
	<xsl:call-template name="write-chunk">
	  <xsl:with-param name="output-filename" select="$root.chunk.filename"/>
	</xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
	<xsl:apply-templates select="h:section|h:div[contains(@data-type, 'part')]|h:nav[contains(@data-type, 'toc')]"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
       
  <xsl:template match="h:section|h:div[contains(@data-type, 'part')]|h:nav[contains(@data-type, 'toc')]">
    <xsl:variable name="is.chunk" select="htmlbook:is-chunk(.)"/>
    <!-- <xsl:message>Element name: <xsl:value-of select="local-name()"/>, data-type name: <xsl:value-of select="@data-type"/>, Is chunk: <xsl:value-of select="$is.chunk"/></xsl:message> -->
    <xsl:choose>
      <xsl:when test="$is.chunk = 1">
	<xsl:variable name="output-filename">
	  <xsl:call-template name="output-filename-for-chunk"/>
	</xsl:variable>
	<xsl:call-template name="write-chunk">
	  <xsl:with-param name="output-filename" select="$output-filename"/>
	</xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
	<xsl:apply-imports/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="full-output-filename">
    <!-- NOTES ON LOGIC FOR THIS TEMPLATE -->
    <!-- When using an XSLT 1.0 processor that relies on exsl:document, this template takes into account the fact that -->
    <!-- nested exsl:document calls change context directory on which relative filepaths are based, 
	 resulting in nested outputdir/outputdir filenames for chunks within chunks -->
    <!-- From the docs at http://www.exslt.org/exsl/elements/document/ -->
    <!-- When the href attribute of a subsidiary document is a relative URI, 
	 the relative URI is resolved into an absolute URI only if and when the subsidiary document is output. 
	 The output URI of the document with which the subsidiary document is associated (ie the output URI of 
	 its parent in the tree of documents) is used as the base URI. The resulting absolute URI is used as the 
	 output URI of the subsidiary document. -->
    <!-- As a workaround, we just omit $outputdir from $full-output-filename for nested chunks
	 to ensure that all chunk documents are in the same output directory -->
    <xsl:param name="chunk" select="."/>
    <xsl:param name="output-filename"/>
    
    <xsl:variable name="chars-to-append-to-outputdir">
      <xsl:if test="$outputdir != '' and substring($outputdir, string-length($outputdir), 1) != '/'">
	<!-- Append a / if outputdir doesn't already end with one --> 
	<xsl:text>/</xsl:text>
      </xsl:if>
    </xsl:variable>

    <xsl:variable name="xsl2support">
      <xsl:sequence select="'1'">
	<xsl:fallback><xsl:text>0</xsl:text></xsl:fallback>
      </xsl:sequence>
    </xsl:variable>

    <xsl:variable name="full-output-filename">
      <!-- Check if we've got an absolute filepath in $outputdir, or if $outputdir is specified and we're *not* processing a nested chunk -->
      <xsl:choose>
	<!-- We can safely include the $outputdir if we're using an XSLT 2.0 processor that will support result-document -->
	<!-- xsl:sequence is acceptable proxy for xsl:result-document -->
	<xsl:when test="$xsl2support = '1'">
	  <xsl:value-of select="concat($outputdir, $chars-to-append-to-outputdir)"/>
	</xsl:when>
	<!-- $outputdir is specified and is absolute filepath; we should include it -->
	<xsl:when test="starts-with($outputdir, '/')">
	  <xsl:value-of select="concat($outputdir, $chars-to-append-to-outputdir)"/>
	</xsl:when>
	<xsl:when test="self::h:body">
	  <!-- Root Chunk! Needs $outputdir in full file path-->
	  <xsl:value-of select="concat($outputdir, $chars-to-append-to-outputdir)"/>
	</xsl:when>
	<xsl:when test="$outputdir != '' and not($generate.root.chunk = 1) and not($chunk[ancestor::*[htmlbook:is-chunk(.) = 1]])">
	  <!-- $outputdir is specified and *is not* absolute filepath, 
	       and generate.root.chunk is not specified (if it is, then previous "when" will set the outputdir properly),
	       and chunk *is not* a nested chunk -->
	  <!-- Because this *is not* a nested chunk, we need to include $outputdir in full file path -->
	  <xsl:value-of select="concat($outputdir, $chars-to-append-to-outputdir)"/>
	</xsl:when>	
	<!-- In all other cases (i.e., we're processing a nested chunk, or $outputdir was not specified), we can omit $outputdir from $full-output-filename -->
      </xsl:choose>
      <xsl:value-of select="$output-filename"/>
    </xsl:variable>
    <xsl:value-of select="$full-output-filename"/>
  </xsl:template>

  <xsl:template match="@*|node()" mode="process-chunk-wrapper">
    <xsl:param name="chunk.node"/> <!-- Contains node that will serve as root of chunk -->
    <xsl:param name="chunk.content"/> <!-- Contains XSL-processsed content of $chunk.node -->
    <!-- Copy to output everything in chunk wrapper that is not the <?yield?> PI -->
    <xsl:copy>
      <xsl:apply-templates select="@*|node()" mode="process-chunk-wrapper">
	<xsl:with-param name="chunk.node" select="$chunk.node"/>
	<xsl:with-param name="chunk.content" select="$chunk.content"/>
      </xsl:apply-templates>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="h:nav[@data-type = 'toc']" mode="process-chunk-wrapper">
    <xsl:param name="chunk.node"/>
    <xsl:param name="chunk.content"/>
    <!-- Only generate a TOC if we're not outputting the TOC chunk (don't want double TOCs in a file) -->
    <xsl:if test="not($chunk.node[self::h:nav[@data-type = 'toc']])">
      <xsl:call-template name="generate-toc">
	<xsl:with-param name="toc.node" select="."/>
	<!-- Use content root as scope. -->
	<!-- ToDo: Further parameterization for mini-TOCs (e.g., chapter TOC, appendix TOC, etc.)? -->
	<xsl:with-param name="scope" select="$chunk.node/ancestor::*[not(ancestor::*)]"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>

  <xsl:template match="h:script" mode="process-chunk-wrapper">
    <xsl:param name="chunk.node"/>
    <xsl:param name="chunk.content"/>
    <!-- Special handling to ensure <script> tags are not self-closing (i.e., no <script/>), as that causes problems in many browsers -->
    <xsl:copy>
      <xsl:apply-templates select="@*|node()" mode="process-chunk-wrapper">
	<xsl:with-param name="chunk.node" select="$chunk.node"/>
	<xsl:with-param name="chunk.content" select="$chunk.content"/>
      </xsl:apply-templates>
      <xsl:if test="not(node())">
	<xsl:text> </xsl:text>
      </xsl:if>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="processing-instruction('yield')" mode="process-chunk-wrapper">
    <xsl:param name="chunk.node"/> <!-- Contains node that will serve as root of chunk -->
    <xsl:param name="chunk.content"/> <!-- Contains XSL-processed content of $chunk.node -->

    <!-- This is our <?yield?> PI, which is the chunk content placeholder -->
    <!-- Drop the content in here -->
    <xsl:copy-of select="exsl:node-set($chunk.content)"/>
  </xsl:template>

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
      <!-- If there's a custom chunk wrapper, use that to wrap the output HTML -->
      <xsl:when test="$custom.chunk.wrapper != ''">
	<xsl:variable name="chunk.content">
	  <xsl:apply-imports/>
	</xsl:variable>
	<xsl:variable name="chunk.wrapper" select="document($custom.chunk.wrapper)"/>
	<xsl:apply-templates select="exsl:node-set($chunk.wrapper)" mode="process-chunk-wrapper">
	  <xsl:with-param name="chunk.node" select="."/> <!-- Contains node that will serve as root of chunk -->
	  <xsl:with-param name="chunk.content" select="$chunk.content"/> <!-- Contains XSL-processed content of $chunk.node -->
	</xsl:apply-templates>
      </xsl:when>
      <!-- Otherwise, go ahead and do the following default chunk processing -->
      <xsl:when test="not(self::h:html)">
	<html>
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

  <xsl:template name="output-filename-for-chunk">
    <xsl:param name="node" select="."/>
    <xsl:param name="original-call" select="1"/>

    <!-- Need to set the context node appropriately before doing xsl:number call later on -->
    <xsl:for-each select="$node">

      <xsl:variable name="node-name" select="local-name(.)"/>
      <xsl:variable name="node-data-type" select="@data-type"/>

      <!-- Check to see if parent is also chunk, in which case, call template recursively -->
      <xsl:variable name="parent-node" select="parent::*"/>
      <xsl:variable name="parent-is-chunk" select="htmlbook:is-chunk($parent-node)"/>
      <xsl:if test="$parent-is-chunk = '1'">
	<xsl:call-template name="output-filename-for-chunk">
	  <xsl:with-param name="node" select="$parent-node"/>
	  <!-- Set $original-call to 0 for recursive calls of function -->
	  <xsl:with-param name="original-call" select="0"/>
	</xsl:call-template>
      </xsl:if>
      <!-- We are assuming (in accordance with HTMLBook spec) that if an element is chunkable, it has a @data-type -->
      <xsl:variable name="filename-prefix-from-data-type">
	<xsl:call-template name="get-param-value-from-key">
	  <xsl:with-param name="parameter" select="$output.filename.prefix.by.data-type"/>
	  <xsl:with-param name="key" select="$node-data-type"/>
	</xsl:call-template>
      </xsl:variable>
      <!-- If prefix is specified in $filename-prefix-from-data-type, then use that -->
      <xsl:choose>
	<xsl:when test="$filename-prefix-from-data-type != ''">
	  <xsl:value-of select="$filename-prefix-from-data-type"/>
	</xsl:when>
	<xsl:otherwise>
	  <!-- Otherwise, fall back to data-type name -->
	  <xsl:value-of select="$node-data-type"/>
	</xsl:otherwise>
      </xsl:choose>
      <xsl:number count="*[local-name() = $node-name and @data-type = $node-data-type]" format="01"/>
      <xsl:if test="$original-call = 1">
	<!-- ToDo: Parameterize me to allow use of different filename extension? -->
	<xsl:text>.html</xsl:text>
      </xsl:if>
    </xsl:for-each>
  </xsl:template>

  <!-- Custom XREF template in chunk.xsl, because we need to take chunk filename into account, and update hrefs. -->
  <!-- All XREFs must be tagged with a @data-type containing XREF -->
  <xsl:template match="h:a[contains(@data-type, 'xref')]" name="process-as-xref">
    <xsl:param name="autogenerate-xrefs" select="$autogenerate-xrefs"/>
    <xsl:variable name="calculated-output-href">
      <xsl:call-template name="calculate-output-href">
	<xsl:with-param name="source-href-value" select="@href"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="href-anchor" select="substring-after($calculated-output-href, '#')"/>
    <xsl:variable name="is-xref">
      <xsl:call-template name="href-is-xref">
	<xsl:with-param name="href-value" select="@href"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:copy>
      <xsl:apply-templates select="@*[not(name() = 'href')]"/>
      <xsl:choose>
	<xsl:when test="(count(key('id', $href-anchor)) &gt; 0) and ($is-xref = 1)">
	  <xsl:variable name="target" select="key('id', $href-anchor)[1]"/>
	  <!-- Regenerate the href here, to ensure it accurately points to correct location, including chunk filename) -->
	  <xsl:attribute name="href">
	    <xsl:call-template name="href.target">
	      <xsl:with-param name="object" select="$target"/>
	      <xsl:with-param name="source-link-node" select="."/>
	    </xsl:call-template>
	  </xsl:attribute>
	</xsl:when>
	<xsl:otherwise>
	  <xsl:call-template name="log-message">
	    <xsl:with-param name="type" select="'WARNING'"/>
	    <xsl:with-param name="message">
	      <xsl:text>Unable to locate target for XREF with @href value:</xsl:text>
	      <xsl:value-of select="@href"/>
	    </xsl:with-param>
	  </xsl:call-template>
	  <!-- Oh well, just copy any existing href to output -->
	  <xsl:apply-templates select="@href"/>
	</xsl:otherwise>
      </xsl:choose>
      <xsl:choose>
	<!-- Generate XREF text node if $autogenerate-xrefs is enabled -->
	<xsl:when test="($autogenerate-xrefs = 1) and ($is-xref = 1)">
	  <xsl:choose>
	    <!-- If we can locate the target, process gentext with "xref-to" -->
	    <xsl:when test="count(key('id', $href-anchor)) > 0">
	      <xsl:variable name="target" select="key('id', $href-anchor)[1]"/>
	      <xsl:apply-templates select="$target" mode="xref-to">
		<xsl:with-param name="referrer" select="."/>
		<xsl:with-param name="xrefstyle" select="@data-xrefstyle"/>
	      </xsl:apply-templates>
	    </xsl:when>
	    <!-- We can't locate the target; fall back on ??? -->
	    <xsl:otherwise>	      
	      <xsl:text>???</xsl:text>
	    </xsl:otherwise>
	  </xsl:choose>
	</xsl:when>
	<!-- Otherwise, just process node as is -->
	<xsl:otherwise>
	  <xsl:apply-templates/>
	</xsl:otherwise>
      </xsl:choose>
    </xsl:copy>
  </xsl:template>

    <!-- href and content handling for a elements that are not indexterms, xrefs, or footnoterefs -->
<xsl:template match="h:a[not((contains(@data-type, 'xref')) or
		               (contains(@data-type, 'footnoteref')) or
			       (contains(@data-type, 'indexterm')))][@href]">
    <!-- If the element is empty, does not have data-type="link", and is a valid XREF, go ahead and treat it like an <a> element with data-type="xref" -->
    <xsl:variable name="is-xref">
      <xsl:call-template name="href-is-xref">
	<xsl:with-param name="href-value" select="@href"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="calculated-output-href">
      <xsl:call-template name="calculate-output-href">
	<xsl:with-param name="source-href-value" select="@href"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="href-anchor" select="substring-after($calculated-output-href, '#')"/>
    <xsl:choose>
      <xsl:when test="(not(node())) and 
		      ($is-xref = 1) and
		      not(@data-type='link')">
	<xsl:call-template name="process-as-xref"/>
      </xsl:when>
      <!-- If href is an xref then process href -->
      <xsl:when test="$is-xref = 1">
	<xsl:copy>
	  <xsl:apply-templates select="@*[not(name(.) = 'href')]"/>
	  <xsl:attribute name="href">
	    <xsl:choose>
	      <xsl:when test="(count(key('id', $href-anchor)) &gt; 0) and ($is-xref = 1)">
		<xsl:variable name="target" select="key('id', $href-anchor)[1]"/>
		<!-- Regenerate the href here, to ensure it accurately points to correct location, including chunk filename) -->
		<xsl:call-template name="href.target">
		  <xsl:with-param name="object" select="$target"/>
		  <xsl:with-param name="source-link-node" select="."/>
		</xsl:call-template>
	      </xsl:when>
	      <xsl:otherwise>
		  <xsl:call-template name="log-message">
		    <xsl:with-param name="type" select="'WARNING'"/>
		    <xsl:with-param name="message">
		      <xsl:text>Unable to locate target for a element with @href value:</xsl:text>
		      <xsl:value-of select="@href"/>
		    </xsl:with-param>
		  </xsl:call-template>
		<!-- Oh well, just copy any existing href to output -->
		<xsl:value-of select="@href"/>
	      </xsl:otherwise>
	    </xsl:choose>
	  </xsl:attribute>
	  <xsl:apply-templates/>
	</xsl:copy>
      </xsl:when>
      <!-- Otherwise, no special processing -->
      <xsl:otherwise>
	<xsl:copy>
	  <xsl:apply-templates select="@*|node()"/>
	</xsl:copy>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Generate target @href value pointing to given node, in the appropriate chunk -->
  <!-- Borrowed and adapted from xhtml/html.xsl and xhtml/chunk-common.xsl in docbook-xsl stylesheets -->
  <xsl:template name="href.target">
    <xsl:param name="context" select="."/>
    <xsl:param name="object" select="."/>
    <xsl:param name="source-link-node"/>

    <!-- Get the filename for the target chunk -->
    <xsl:variable name="target.chunk.filename">
      <xsl:call-template name="filename-for-node">
	<xsl:with-param name="node" select="$object"/>
      </xsl:call-template>
    </xsl:variable>

    <xsl:if test="$target.chunk.filename = ''">
      <xsl:call-template name="log-message">
	<xsl:with-param name="type" select="'WARNING'"/>
	<xsl:with-param name="message">
	  <xsl:text>Error: Chunker unable to locate output file containing target node </xsl:text>
	  <xsl:call-template name="object.id">
	    <xsl:with-param name="object" select="$object"/>
	  </xsl:call-template>
	  <xsl:text>. Hyperlink may not generate properly</xsl:text>
	</xsl:with-param>
      </xsl:call-template>
    </xsl:if>

    <!-- We only need to prepend filename if target is in different chunk than hyperlink, so... -->
    <!-- Get the filename of the source hyperlink chunk, and then add it to the link if it's different than target chunk filename -->
    <xsl:choose>
      <!-- If we know the source link node, get its filename and check if it's the same as target chunk filename -->
      <xsl:when test="$source-link-node">
	<xsl:variable name="source.link.chunk.filename">
	  <xsl:call-template name="filename-for-node">
	    <xsl:with-param name="node" select="$source-link-node"/>
	  </xsl:call-template>
	</xsl:variable>
	<!-- If source-link filename and target-chunk filename are different, we need to output the filename as part of the link href -->
	<xsl:if test="$source.link.chunk.filename != $target.chunk.filename">
	  <xsl:value-of select="$target.chunk.filename"/>
	</xsl:if>
      </xsl:when>
      <xsl:otherwise>
	<!-- We don't know the source link node; output the filename as part of the link href by default -->
	<xsl:value-of select="$target.chunk.filename"/>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:text>#</xsl:text>
    <xsl:call-template name="object.id">
      <xsl:with-param name="object" select="$object"/>
    </xsl:call-template>
  </xsl:template>




  <!-- Given a node, return the filename for the chunk it's in -->
  <xsl:template name="filename-for-node">
    <xsl:param name="node"/>

    <xsl:variable name="chunk.node" select="htmlbook:chunk-for-node($node, $chunks)"/>

    <!-- Now get filename for chunk -->
    <xsl:variable name="chunk-filename">
      <xsl:choose>
	<!-- When we do have a chunk, get its filename -->
	<xsl:when test="$chunk.node">
	  <xsl:call-template name="output-filename-for-chunk">
	    <xsl:with-param name="node" select="$chunk.node"/>
	  </xsl:call-template>
	</xsl:when>
	<xsl:otherwise>
	  <xsl:if test="$generate.root.chunk = 1">
	    <!-- Root must be the chunk -->
	    <xsl:value-of select="$root.chunk.filename"/>
	  </xsl:if>
	</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:value-of select="$chunk-filename"/>
  </xsl:template>

  <!-- For chunked output, we want to customize generate-footnotes to only generate the footnotes in a specific chunk, and to put them
       at the end of that chunk -->
  <xsl:template name="generate-footnotes">

    <!-- Only generate footnotes if the current node is a chunk -->
    <xsl:if test="htmlbook:is-chunk(.)">

      <xsl:variable name="all-footnotes" select="//h:span[@data-type='footnote']"/>

      <!-- Get a list of all chunk filenames corresponding to each footnote node -->
      <xsl:variable name="filenames-for-footnotes">
	<xsl:for-each select="$all-footnotes">	
	  <xsl:call-template name="filename-for-node">
	    <xsl:with-param name="node" select="."/>
	  </xsl:call-template>
	</xsl:for-each>
      </xsl:variable>
      
      <!-- Get the filename of the current chunk -->
      <xsl:variable name="this-chunk-filename">
	<xsl:call-template name="filename-for-node">
	  <xsl:with-param name="node" select="."/>
	</xsl:call-template>
      </xsl:variable>

      <!-- We're in a chunk, but before we generate footnotes, confirm there are actually footnotes in the chunk -->
      <!-- If this chunk's filename is in the list of footnote chunk filenames, then there are indeed footnotes in this chunk -->
      <xsl:if test="contains($filenames-for-footnotes, $this-chunk-filename)">
   
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
	  <xsl:for-each select="$all-footnotes">
	    <xsl:variable name="footnote-chunk-filename">
	      <xsl:call-template name="filename-for-node">
		<xsl:with-param name="node" select="."/>
	      </xsl:call-template>
	    </xsl:variable>
	    <xsl:if test="$footnote-chunk-filename = $this-chunk-filename">
	      <xsl:apply-templates select="." mode="generate.footnote"/>
	    </xsl:if>
	  </xsl:for-each>
	</xsl:element>
      </xsl:if>
    </xsl:if>
  </xsl:template>

  <!-- Special handling for the following navigation links:
       1. Previous link (go to the previous chunk in the book sequence)
       2. Next link (go to the next chunk in the book sequence)
       3. TOC link (go to the TOC chunk)
    -->

  <!-- Support use of <?prev_link?> to insert link to previous chunk in book sequence -->
  <xsl:template match="processing-instruction('prev_link')" name="prev_link" mode="process-chunk-wrapper">
    <xsl:param name="chunk.node" select="parent::*"/>

    <xsl:choose>
      <xsl:when test="htmlbook:chunk-for-node($chunk.node, $chunks)">
	<xsl:variable name="current.chunk" select="htmlbook:chunk-for-node($chunk.node, $chunks)"/>
	<xsl:variable name="previous.chunk" select="$chunks[descendant::*[generate-id(.) = generate-id($current.chunk)]|
						            following::*[generate-id(.) = generate-id($current.chunk)]][last()]"/>
	<xsl:if test="$previous.chunk">
<!--	  <xsl:message>Current chunk: <xsl:value-of select="$current.chunk/@id"/>; Previous chunk: <xsl:value-of select="$previous.chunk/@id"/>; Output filename: 	      <xsl:call-template name="output-filename-for-chunk">
		<xsl:with-param name="node" select="$previous.chunk"/>
              </xsl:call-template>
</xsl:message> -->
	  <a>
	    <xsl:attribute name="href">
	      <xsl:call-template name="output-filename-for-chunk">
		<xsl:with-param name="node" select="$previous.chunk"/>
              </xsl:call-template>
	    </xsl:attribute>
	    <xsl:text>Previous</xsl:text>
	  </a>
	</xsl:if>
      </xsl:when>
      <xsl:otherwise>
	<xsl:call-template name="log-message">
	  <xsl:with-param name="type" select="'ERROR'"/>
	  <xsl:with-param name="message">
	    <xsl:text>Unable to find proper context for previous-link placeholder. Link will not be generated</xsl:text>
	  </xsl:with-param>
	</xsl:call-template>	
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Support use of <?next_link?> to insert link to previous chunk in book sequence -->
  <xsl:template match="processing-instruction('next_link')" name="next_link" mode="process-chunk-wrapper">
    <xsl:param name="chunk.node" select="parent::*"/>

    <xsl:choose>
      <xsl:when test="htmlbook:chunk-for-node($chunk.node, $chunks)">
	<xsl:variable name="current.chunk" select="htmlbook:chunk-for-node($chunk.node, $chunks)"/>
	<xsl:variable name="next.chunk" select="$chunks[ancestor::*[generate-id(.) = generate-id($current.chunk)]|
						            preceding::*[generate-id(.) = generate-id($current.chunk)]][1]"/>
	<xsl:if test="$next.chunk">
<!--	  <xsl:message>Current chunk: <xsl:value-of select="$current.chunk/@id"/>; Next chunk: <xsl:value-of select="$next.chunk/@id"/>; Output filename: 	      <xsl:call-template name="output-filename-for-chunk">
		<xsl:with-param name="node" select="$next.chunk"/>
              </xsl:call-template>
</xsl:message> -->
	  <a>
	    <xsl:attribute name="href">
	      <xsl:call-template name="output-filename-for-chunk">
		<xsl:with-param name="node" select="$next.chunk"/>
              </xsl:call-template>
	    </xsl:attribute>
	    <xsl:text>Next</xsl:text>
	  </a>
	</xsl:if>
      </xsl:when>
      <xsl:otherwise>
	<xsl:call-template name="log-message">
	  <xsl:with-param name="type" select="'ERROR'"/>
	  <xsl:with-param name="message">
	    <xsl:text>Unable to find proper context for next-link placeholder. Link will not be generated</xsl:text>
	  </xsl:with-param>
	</xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Support use of <?toc_link?> to insert link to table of contents in book sequence -->
  <xsl:template match="processing-instruction('toc_link')" name="toc_link" mode="process-chunk-wrapper">
    <xsl:variable name="toc_chunks" select="$chunks[self::h:nav[@data-type='toc']]"/>
    <xsl:if test="count($toc_chunks) &gt; 1">
      <xsl:call-template name="log-message">
	<xsl:with-param name="type" select="'WARNING'"/>
	<xsl:with-param name="message">
	  <xsl:text>More than one TOC in book. TOC navigation link will be generated for the *first* TOC.</xsl:text>
	</xsl:with-param>
      </xsl:call-template>
    </xsl:if>
    <xsl:choose>
      <xsl:when test="count($toc_chunks) &gt; 0">
	<a>
	  <xsl:attribute name="href">
	    <xsl:call-template name="output-filename-for-chunk">
	      <xsl:with-param name="node" select="$toc_chunks[1]"/>
            </xsl:call-template>
	  </xsl:attribute>
	  <xsl:text>Table of Contents</xsl:text>
	</a>
      </xsl:when>
      <xsl:otherwise>
	<xsl:call-template name="log-message">
	  <xsl:with-param name="type" select="'WARNING'"/>
	  <xsl:with-param name="message">
	    <xsl:text>No TOC in book. No TOC navigation link will be generated.</xsl:text>
	  </xsl:with-param>
	</xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
</xsl:stylesheet> 
