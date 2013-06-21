<xsl:stylesheet version="1.0"
		xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns:exsl="http://exslt.org/common"
		xmlns:set="http://exslt.org/sets"
		xmlns:h="http://www.w3.org/1999/xhtml"
		xmlns:htmlbook="https://github.com/oreillymedia/HTMLBook"
		xmlns:func="http://exslt.org/functions"
		xmlns="http://www.w3.org/1999/xhtml"
		extension-element-prefixes="exsl func set"
		exclude-result-prefixes="exsl h func set">

  <!-- Chunk template used to split content among multiple .html files -->

  <!-- ToDo: For XREF hyperlinks to ids that are in the same chunk, no need to prepend filename to anchor (although it probably doesn't hurt) -->
  <!-- ToDo: Add "previous" and "next" links as in the docbook-xsl stylesheets? -->

  <!-- Imports htmlbook.xsl -->
  <xsl:import href="htmlbook.xsl"/>

  <xsl:output method="xml"
              encoding="UTF-8"/>
  <xsl:preserve-space elements="*"/>

  <xsl:key name="chunks" match="h:section|h:div[@class='part']" use="htmlbook:is-chunk(.)"/>

  <!-- Specify a number from 0 to 5, where 0 means chunk at top-level sections (part, chapter, appendix), and 1-5 means chunk at the corresponding sect level (sect1 - sect5) -->
  <xsl:param name="chunk.level" select="0"/>

  <!-- Specify the filename for the root chunk -->
  <xsl:param name="root.chunk.filename" select="'index.html'"/>

  <!-- Specify a prefix for output filename for a given class -->
  <xsl:param name="output.filename.prefix.by.class">
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
  <!-- Todo: deal with situation where nested exsl:document calls change context directory on which relative filepaths are based, resulting in nested outputdir/outputdir filenames for chunks within chunks -->
  <!-- From the docs at http://www.exslt.org/exsl/elements/document/ -->
  <!--  When the href attribute of a subsidiary document is a relative URI, the relative URI is resolved into an absolute URI only if and when the subsidiary document is output. The output URI of the document with which the subsidiary document is associated (ie the output URI of its parent in the tree of documents) is used as the base URI. The resulting absolute URI is used as the output URI of the subsidiary document. -->
  <!-- Simplest solution might just be to prepend ".." as needed -->
  <xsl:param name="outputdir"/>

  <xsl:template match="/h:html">
    <xsl:apply-templates select="h:body"/>
  </xsl:template>

  <!-- Logic for root chunk -->
  <xsl:template match="h:body">
    <xsl:call-template name="write-chunk">
      <xsl:with-param name="output-filename" select="$root.chunk.filename"/>
    </xsl:call-template>
  </xsl:template>
       
  <xsl:template match="h:section|h:div[contains(@class, 'part')]|h:nav[contains(@class, 'toc')]">
    <xsl:variable name="is.chunk" select="htmlbook:is-chunk(.)"/>
    <!-- <xsl:message>Element name: <xsl:value-of select="local-name()"/>, Class name: <xsl:value-of select="@class"/>, Is chunk: <xsl:value-of select="$is.chunk"/></xsl:message> -->
    <xsl:choose>
      <xsl:when test="$is.chunk = 1">
	<xsl:variable name="output-filename">
	  <xsl:call-template name="output-filename-for-chunk"/>
	</xsl:variable>
	<!-- <xsl:message>Output filename: <xsl:value-of select="$output-filename"/></xsl:message> -->

	<!-- <xsl:message>Full output filename: <xsl:value-of select="$full-output-filename"/></xsl:message> -->
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
    <xsl:param name="output-filename"/>
    <xsl:variable name="full-output-filename">
      <xsl:if test="$outputdir != ''">
	<xsl:value-of select="concat($outputdir, '/')"/>
      </xsl:if>
      <xsl:value-of select="$output-filename"/>
    </xsl:variable>
    <xsl:value-of select="$full-output-filename"/>
  </xsl:template>

  <xsl:template name="write-chunk">
    <xsl:param name="output-filename"/>
    <xsl:variable name="full-output-filename">
      <xsl:call-template name="full-output-filename">
	<xsl:with-param name="output-filename" select="$output-filename"/>
      </xsl:call-template>
    </xsl:variable>
<!--    <xsl:message><xsl:value-of select="$full-output-filename"/></xsl:message> -->
    <exsl:document href="{$full-output-filename}" method="xml">
      <xsl:value-of select="'&lt;!DOCTYPE html&gt;'" disable-output-escaping="yes"/>
      <!-- Only add the <html>/<head> if they don't already exist -->
      <xsl:choose>
	<xsl:when test="not(self::h:html)">
	  <html>
	    <!-- ToDo: What else do we want in the <head>? -->
	    <head>
	      <title>
		<xsl:variable name="title-markup">
		  <xsl:apply-templates select="." mode="title.markup"/>
		</xsl:variable>
		<xsl:value-of select="$title-markup"/>
	      </title>
	    </head>
	    <xsl:choose>
	      <!-- Only add the body tag if doesn't already exist -->
	      <xsl:when test="not(self::h:body)">
		<body class="book">
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
    </exsl:document>
  </xsl:template>

  <xsl:template name="output-filename-for-chunk">
    <xsl:param name="node" select="."/>
    <xsl:param name="original-call" select="1"/>

    <!-- Need to set the context node appropriately before doing xsl:number call later on -->
    <xsl:for-each select="$node">

      <xsl:variable name="node-name" select="local-name(.)"/>
      <xsl:variable name="node-class" select="@class"/>

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
      <!-- We are assuming (in accordance with HTMLBook spec) that if an element is chunkable, it has a @class -->
      <xsl:variable name="filename-prefix-from-class">
	<xsl:call-template name="get-param-value-from-key">
	  <xsl:with-param name="parameter" select="$output.filename.prefix.by.class"/>
	  <xsl:with-param name="key" select="$node-class"/>
	</xsl:call-template>
      </xsl:variable>
      <!-- If prefix is specified in $filename-prefix-from-class, then use that -->
      <xsl:choose>
	<xsl:when test="$filename-prefix-from-class != ''">
	  <xsl:value-of select="$filename-prefix-from-class"/>
	</xsl:when>
	<xsl:otherwise>
	  <!-- Otherwise, fall back to class name -->
	  <xsl:value-of select="$node-class"/>
	</xsl:otherwise>
      </xsl:choose>
      <xsl:number count="*[local-name() = $node-name and @class = $node-class]" format="01"/>
      <xsl:if test="$original-call = 1">
	<!-- ToDo: Parameterize me to allow use of different filename extension? -->
	<xsl:text>.html</xsl:text>
      </xsl:if>
    </xsl:for-each>
  </xsl:template>

  <func:function name="htmlbook:is-chunk">
    <xsl:param name="node" select="."/>
    <xsl:choose>
      <xsl:when test="$node[self::h:div[contains(@class, 'part')]]">
	<func:result>1</func:result>
      </xsl:when>
      <xsl:when test="$node[self::h:section[contains(@class, 'acknowledgments') or
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
		      contains(@class, 'toc')]]">
	<func:result>1</func:result>
      </xsl:when>
      <xsl:when test="$node[self::h:nav[contains(@class, 'toc')]]">
	<func:result>1</func:result>
      </xsl:when>
      <xsl:when test="$node[self::h:section[contains(@class, 'sect')]]">
	<xsl:variable name="sect-level">
	  <xsl:value-of select="substring(substring-after($node/@class, 'sect'), 1, 1)"/>
	</xsl:variable>
	<xsl:if test="($sect-level = '1' or $sect-level = '2' or $sect-level = '3' or $sect-level = '4' or $sect-level = '5') and
		      $sect-level &lt;= $chunk.level">
	  <func:result>1</func:result>
	</xsl:if>	
      </xsl:when>
      <xsl:otherwise>
	<func:result/>
      </xsl:otherwise>
    </xsl:choose>
  </func:function>

  <!-- Custom XREF template in chunk.xsl, because we need to take chunk filename into account, and update hrefs. -->
  <!-- All XREFs must be tagged with a @class containing XREF -->
  <xsl:template match="h:a[contains(@class, 'xref')]">
    <xsl:variable name="href-anchor">
      <xsl:choose>
	<!-- If href contains an # (as it should), we're going to assume the subsequent text is the referent id -->
	<xsl:when test="contains(@href, '#')">
	  <xsl:value-of select="substring-after(@href, '#')"/>
	</xsl:when>
	<!-- Otherwise, we'll just assume the entire href is the referent id -->
	<xsl:otherwise>
	  <xsl:value-of select="@href"/>
	</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:copy>
      <xsl:apply-templates select="@*[not(local-name() = 'href')]"/>
      <xsl:choose>
	<xsl:when test="count(key('id', $href-anchor)) > 0">
	  <xsl:variable name="target" select="key('id', $href-anchor)[1]"/>
	  <!-- Regenerate the href here, to ensure it accurately points to correct location, including chunk filename) -->
	  <xsl:attribute name="href">
	    <xsl:call-template name="href.target">
	      <xsl:with-param name="object" select="$target"/>
	    </xsl:call-template>
	  </xsl:attribute>
	</xsl:when>
	<xsl:otherwise>
	  <xsl:message>Unable to locate target for XREF with @href value: <xsl:value-of select="@href"/></xsl:message>
	  <!-- Oh well, just copy any existing href to output -->
	  <xsl:apply-templates select="@href"/>
	</xsl:otherwise>
      </xsl:choose>
      <xsl:choose>
	<!-- Generate XREF text node if <a> is either empty or $xref-placeholder-overwrite-contents = 1 -->
	<xsl:when test="$autogenerate-xrefs = 1 and (. = '' or $xref-placeholder-overwrite-contents = 1)">
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

  <!-- Generate target @href value pointing to given node, in the appropriate chunk -->
  <!-- Borrowed and adapted from xhtml/html.xsl and xhtml/chunk-common.xsl in docbook-xsl stylesheets -->
  <xsl:template name="href.target">
    <xsl:param name="context" select="."/>
    <xsl:param name="object" select="."/>
    <!-- Figure out which chunk this element belongs to: -->

    <!-- 1. Get a nodeset of all chunks in this document -->
    <xsl:variable name="chunks" select="key('chunks', '1')"/> <!-- All chunks have an is-chunk() value of 1 -->

    <!-- 2. Get a nodeset of current element and all its ancestors, which could potentially be chunks -->
    <xsl:variable name="self-and-ancestors" select="$object/ancestor-or-self::*"/>

    <!-- 3. Find out which of these "self and ancestors" are also chunks -->
    <xsl:variable name="self-and-ancestors-that-are-chunks" select="set:intersection($self-and-ancestors, $chunks)"/>

    <!-- 4. Target chunk is the last (lowest in hierarchy) in this nodeset -->
    <xsl:variable name="target.chunk" select="$self-and-ancestors-that-are-chunks[last()]"/>

    <!-- Now get filename for chunk -->
    <xsl:variable name="chunk-filename">
      <xsl:choose>
	<!-- When we do have a target chunk, get its filename -->
	<xsl:when test="$target.chunk">
	  <xsl:call-template name="output-filename-for-chunk">
	    <xsl:with-param name="node" select="$target.chunk"/>
	  </xsl:call-template>
	</xsl:when>
	<!-- Otherwise, root must be the chunk -->
	<xsl:otherwise>
	  <xsl:value-of select="$root.chunk.filename"/>
	</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:value-of select="$chunk-filename"/>
    <xsl:text>#</xsl:text>
    <xsl:call-template name="object.id">
      <xsl:with-param name="object" select="$object"/>
    </xsl:call-template>
  </xsl:template>
  
</xsl:stylesheet> 
