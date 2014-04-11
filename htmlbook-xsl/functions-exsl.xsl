<xsl:stylesheet version="1.0"
		xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns:exsl="http://exslt.org/common"
		xmlns:h="http://www.w3.org/1999/xhtml"
		xmlns:htmlbook="https://github.com/oreillymedia/HTMLBook"
		xmlns:func="http://exslt.org/functions"
		xmlns:set="http://exslt.org/sets"
		xmlns="http://www.w3.org/1999/xhtml"
		extension-element-prefixes="exsl func set"
		exclude-result-prefixes="exsl h func set">

  <func:function name="htmlbook:is-chunk">
    <xsl:param name="node"/>
    <xsl:choose>
      <xsl:when test="$node[self::h:div[contains(@data-type, 'part')]]">
	<func:result>1</func:result>
      </xsl:when>
      <xsl:when test="$node[self::h:section[contains(@data-type, 'acknowledgments') or
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
		      contains(@data-type, 'toc')]]">
	<func:result>1</func:result>
      </xsl:when>
      <xsl:when test="$node[self::h:nav[contains(@data-type, 'toc')]]">
	<func:result>1</func:result>
      </xsl:when>
      <xsl:when test="$node[self::h:section[contains(@data-type, 'sect')]]">
	<xsl:variable name="sect-level">
	  <xsl:value-of select="substring(substring-after($node/@data-type, 'sect'), 1, 1)"/>
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

  <!-- Given a node, return the root node of the chunk it's in -->
  <func:function name="htmlbook:chunk-for-node">
    <xsl:param name="node"/>
    <xsl:param name="chunks"/>

    <!-- 1. Get a nodeset of current element and all its ancestors, which could potentially be chunks -->
    <xsl:variable name="self-and-ancestors" select="$node/ancestor-or-self::*"/>

    <!-- 2. Find out which of these "self and ancestors" are also chunks -->
    <xsl:variable name="self-and-ancestors-that-are-chunks" select="set:intersection($self-and-ancestors, $chunks)"/>

    <!-- 3. Desired chunk is the last (lowest in hierarchy) in this nodeset -->
    <xsl:variable name="chunk.node" select="$self-and-ancestors-that-are-chunks[last()]"/>

    <xsl:choose>
      <xsl:when test="$chunk.node">
	<func:result select="$chunk.node"/>
      </xsl:when>
      <xsl:otherwise>
	<func:result/>
      </xsl:otherwise>
    </xsl:choose>
  </func:function>

  <func:function name="htmlbook:section-depth">
    <xsl:param name="node"/>
    <xsl:choose>
      <xsl:when test="$node[self::h:section] and 
		      $node/@data-type and
		      (substring($node/@data-type, string-length($node/@data-type), 1) = '1' or
		      substring($node/@data-type, string-length($node/@data-type), 1) = '2' or
		      substring($node/@data-type, string-length($node/@data-type), 1) = '3' or
		      substring($node/@data-type, string-length($node/@data-type), 1) = '4' or
		      substring($node/@data-type, string-length($node/@data-type), 1) = '5')">
	<func:result>
	  <xsl:value-of select="substring($node/@data-type, string-length($node/@data-type), 1)"/>
	</func:result>
      </xsl:when>
      <xsl:otherwise>
	<func:result/>
      </xsl:otherwise>
    </xsl:choose>
  </func:function>
</xsl:stylesheet>
