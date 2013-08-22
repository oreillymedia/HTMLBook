<xsl:stylesheet version="1.0"
		xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns:exsl="http://exslt.org/common"
		xmlns:h="http://www.w3.org/1999/xhtml"
		xmlns:l="http://docbook.sourceforge.net/xmlns/l10n/1.0"
		xmlns="http://www.w3.org/1999/xhtml"
		extension-element-prefixes="exsl"
		exclude-result-prefixes="exsl h">

  <xsl:output method="xml"
              encoding="UTF-8"/>
  <xsl:preserve-space elements="*"/>

  <!-- Default rule for TOC generation -->

  <!-- ToDo: Add support for separate handling for data-type="link", where it's an internal cross-reference, but you definitely
       do not want to override text node -->

  <!-- All XREFs must be tagged with a @data-type containing XREF -->
  <xsl:template match="h:a[contains(@data-type, 'xref')]">
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
      <xsl:apply-templates select="@*"/>
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
		<xsl:call-template name="log-message">
		  <xsl:with-param name="type" select="'WARNING'"/>
		  <xsl:with-param name="message">
		    <xsl:text>Unable to locate target for XREF with @href value: </xsl:text>
		    <xsl:value-of select="@href"/>
		  </xsl:with-param>
		</xsl:call-template>
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

  <!-- Adapted from docbook-xsl templates in xhtml/xref.xsl -->
  <xsl:template match="*" mode="xref-to">
    <xsl:param name="referrer"/>
    <xsl:param name="xrefstyle"/>
    <xsl:param name="verbose" select="1"/>
    
    <xsl:apply-templates select="." mode="object.xref.markup">
      <xsl:with-param name="purpose" select="'xref'"/>
      <xsl:with-param name="xrefstyle" select="$xrefstyle"/>
      <xsl:with-param name="referrer" select="$referrer"/>
      <xsl:with-param name="verbose" select="$verbose"/>
    </xsl:apply-templates>
  </xsl:template>

  <!-- Adapted from docbook-xsl templates in common/gentext.xsl -->
  <!-- For simplicity, not folding in all the special 'select: ' logic (some of which is FO-specific, anyway) -->
<xsl:template match="*" mode="object.xref.markup">
  <xsl:param name="purpose" select="'xref'"/>
  <xsl:param name="xrefstyle"/>
  <xsl:param name="referrer"/>
  <xsl:param name="verbose" select="1"/>

  <xsl:variable name="template">
    <xsl:choose>
      <xsl:when test="starts-with(normalize-space($xrefstyle), 'template:')">
        <xsl:value-of select="substring-after(normalize-space($xrefstyle), 'template:')"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates select="." mode="object.xref.template">
          <xsl:with-param name="purpose" select="$purpose"/>
          <xsl:with-param name="xrefstyle" select="$xrefstyle"/>
          <xsl:with-param name="referrer" select="$referrer"/>
        </xsl:apply-templates>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:if test="$template = '' and $verbose != 0">
    <xsl:call-template name="log-message">
      <xsl:with-param name="type" select="'DEBUG'"/>
      <xsl:with-param name="message">
	<xsl:text>object.xref.markup: empty xref template</xsl:text>
	<xsl:text> for linkend="</xsl:text>
	<xsl:value-of select="@id|@xml:id"/>
	<xsl:text>" and @xrefstyle="</xsl:text>
	<xsl:value-of select="$xrefstyle"/>
	<xsl:text>"</xsl:text>
      </xsl:with-param>
    </xsl:call-template>
  </xsl:if>

  <xsl:choose>
    <xsl:when test="normalize-space($template) != ''">
      <xsl:call-template name="substitute-markup">
	<xsl:with-param name="purpose" select="$purpose"/>
	<xsl:with-param name="xrefstyle" select="$xrefstyle"/>
	<xsl:with-param name="referrer" select="$referrer"/>
	<xsl:with-param name="template" select="$template"/>
	<xsl:with-param name="verbose" select="$verbose"/>
      </xsl:call-template>
    </xsl:when>
    <xsl:otherwise>
      <xsl:text>???</xsl:text>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<!-- ============================================================ -->

<xsl:template match="*" mode="object.xref.template">
  <xsl:param name="purpose"/>
  <xsl:param name="xrefstyle"/>
  <xsl:param name="referrer"/>

  <xsl:variable name="number-and-title-template">
    <xsl:call-template name="gentext.template.exists">
      <xsl:with-param name="context" select="'xref-number-and-title'"/>
      <xsl:with-param name="name">
        <xsl:call-template name="semantic-name"/>
      </xsl:with-param>
    </xsl:call-template>
  </xsl:variable>

  <xsl:variable name="number-template">
    <xsl:call-template name="gentext.template.exists">
      <xsl:with-param name="context" select="'xref-number'"/>
      <xsl:with-param name="name">
        <xsl:call-template name="semantic-name"/>
      </xsl:with-param>
    </xsl:call-template>
  </xsl:variable>

  <xsl:variable name="context">
    <xsl:choose>
      <!-- If we're XREFing a section or a part div, use the $xref.type.for.section.by.data-type variable -->
      <xsl:when test="self::h:section or self::h:div[contains(@data-type, 'part')]">
	<xsl:variable name="xref-type">
	  <xsl:call-template name="get-param-value-from-key">
	    <xsl:with-param name="parameter" select="$xref.type.for.section.by.data-type"/>
	    <xsl:with-param name="key" select="@data-type"/>
	  </xsl:call-template>
	</xsl:variable>
	<xsl:choose>
	  <xsl:when test="($xref-type = 'xref-number-and-title' and $number-and-title-template != 0) or ($xref-type = 'xref-number' and $number-template != 0)">
	    <xsl:value-of select="$xref-type"/>
	  </xsl:when>
	  <xsl:otherwise>
	    <xsl:text>xref</xsl:text>
	  </xsl:otherwise>
	</xsl:choose>
      </xsl:when>
      <xsl:otherwise>
	<xsl:apply-templates select="." mode="xref-type">
	  <xsl:with-param name="number-and-title-template" select="$number-and-title-template"/>
	  <xsl:with-param name="number-template" select="$number-template"/>
	</xsl:apply-templates>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:call-template name="gentext.template">
    <xsl:with-param name="context" select="$context"/>
    <xsl:with-param name="name">
      <xsl:call-template name="semantic-name"/>
    </xsl:with-param>
    <xsl:with-param name="purpose" select="$purpose"/>
    <xsl:with-param name="xrefstyle" select="$xrefstyle"/>
    <xsl:with-param name="referrer" select="$referrer"/>
  </xsl:call-template>

</xsl:template>

<!-- ============================================================ -->

<!-- xref-type templates: should return a value of 'xref-number-and-title', 'xref-number', or 'xref' -->
<!-- If returning 'xref-number-and-title' or 'xref-number', may want to first check if corresponding template exists -->

<xsl:template match="h:table|h:figure|h:div[contains(@data-type, 'example')]" mode="xref-type">
  <xsl:param name="number-and-title-template" select="0"/>
  <xsl:param name="number-template" select="0"/>
  <xsl:choose>
    <xsl:when test="$number-template != 0">
      <xsl:text>xref-number</xsl:text>
    </xsl:when>
    <xsl:otherwise>
      <xsl:text>xref</xsl:text>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<!-- Default xref-type template -->
<xsl:template match="*" mode="xref-type">
  <xsl:param name="number-and-title-template"/>
  <xsl:param name="number-template"/>
  <xsl:text>xref</xsl:text>
</xsl:template>

<!-- ============================================================ -->

<!-- Adapted from docbook-xsl templates in common/gentext.xsl -->
<!-- For reasons of simplicity and relevancy, only supporting %n, %t, and %d substitutions -->
<xsl:template name="substitute-markup">
  <xsl:param name="template" select="''"/>
  <xsl:param name="allow-anchors" select="'0'"/>
  <xsl:param name="title" select="''"/>
  <xsl:param name="subtitle" select="''"/>
  <xsl:param name="docname" select="''"/>
  <xsl:param name="label" select="''"/>
  <xsl:param name="pagenumber" select="''"/>
  <xsl:param name="purpose"/>
  <xsl:param name="xrefstyle"/>
  <xsl:param name="referrer"/>
  <xsl:param name="verbose"/>

  <xsl:choose>
    <xsl:when test="contains($template, '%')">
      <xsl:value-of select="substring-before($template, '%')"/>
      <xsl:variable name="candidate"
             select="substring(substring-after($template, '%'), 1, 1)"/>
      <xsl:choose>
        <xsl:when test="$candidate = 't'">
          <xsl:apply-templates select="." mode="insert.title.markup">
            <xsl:with-param name="purpose" select="$purpose"/>
            <xsl:with-param name="xrefstyle" select="$xrefstyle"/>
            <xsl:with-param name="title">
              <xsl:choose>
                <xsl:when test="$title != ''">
                  <xsl:copy-of select="$title"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:apply-templates select="." mode="title.markup">
                    <xsl:with-param name="allow-anchors" select="$allow-anchors"/>
                    <xsl:with-param name="verbose" select="$verbose"/>
                  </xsl:apply-templates>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:with-param>
          </xsl:apply-templates>
        </xsl:when>
        <xsl:when test="$candidate = 'n'">
          <xsl:apply-templates select="." mode="insert.label.markup">
            <xsl:with-param name="purpose" select="$purpose"/>
            <xsl:with-param name="xrefstyle" select="$xrefstyle"/>
            <xsl:with-param name="label">
              <xsl:choose>
                <xsl:when test="$label != ''">
                  <xsl:copy-of select="$label"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:apply-templates select="." mode="label.markup"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:with-param>
          </xsl:apply-templates>
        </xsl:when>
        <xsl:when test="$candidate = 'd'">
          <xsl:apply-templates select="." mode="insert.direction.markup">
            <xsl:with-param name="purpose" select="$purpose"/>
            <xsl:with-param name="xrefstyle" select="$xrefstyle"/>
            <xsl:with-param name="direction">
              <xsl:choose>
                <xsl:when test="$referrer">
                  <xsl:variable name="referent-is-below">
                    <xsl:for-each select="preceding::h:a[@data-type='xref']">
                      <xsl:if test="generate-id(.) = generate-id($referrer)">1</xsl:if>
                    </xsl:for-each>
                  </xsl:variable>
                  <xsl:choose>
                    <xsl:when test="$referent-is-below = ''">
		      <xsl:call-template name="get-localization-value">
			<xsl:with-param name="gentext-key" select="'above'"/>
		      </xsl:call-template>
		    </xsl:when>
                    <xsl:otherwise>
		      <xsl:call-template name="get-localization-value">
			<xsl:with-param name="gentext-key" select="'below'"/>
		      </xsl:call-template>
                    </xsl:otherwise>
                  </xsl:choose>
                </xsl:when>
                <xsl:otherwise>
		  <xsl:call-template name="log-message">
		    <xsl:with-param name="type" select="'WARNING'"/>
		    <xsl:with-param name="message">
                      <xsl:text>Attempt to use %d in gentext with no referrer!</xsl:text>
		    </xsl:with-param>
		  </xsl:call-template>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:with-param>
          </xsl:apply-templates>
        </xsl:when>
        <xsl:when test="$candidate = '%' ">
          <xsl:text>%</xsl:text>
        </xsl:when>
        <xsl:otherwise>
          <xsl:text>%</xsl:text><xsl:value-of select="$candidate"/>
        </xsl:otherwise>
      </xsl:choose>
      <!-- recurse with the rest of the template string -->
      <xsl:variable name="rest"
            select="substring($template,
            string-length(substring-before($template, '%'))+3)"/>
      <xsl:call-template name="substitute-markup">
        <xsl:with-param name="template" select="$rest"/>
        <xsl:with-param name="allow-anchors" select="$allow-anchors"/>
        <xsl:with-param name="title" select="$title"/>
        <xsl:with-param name="subtitle" select="$subtitle"/>
        <xsl:with-param name="docname" select="$docname"/>
        <xsl:with-param name="label" select="$label"/>
        <xsl:with-param name="pagenumber" select="$pagenumber"/>
        <xsl:with-param name="purpose" select="$purpose"/>
        <xsl:with-param name="xrefstyle" select="$xrefstyle"/>
        <xsl:with-param name="referrer" select="$referrer"/>
        <xsl:with-param name="verbose" select="$verbose"/>
      </xsl:call-template>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="$template"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<!-- ============================================================ -->

<!-- insert.title.markup, insert.label.markup, and insert.direction.markup templates; adapted from docbook-xsl xhtml/xref.xsl stylesheet -->

<xsl:template match="*" mode="insert.label.markup">
  <xsl:param name="purpose"/>
  <xsl:param name="xrefstyle"/>
  <xsl:param name="label"/>

  <xsl:copy-of select="$label"/>
</xsl:template>

<xsl:template match="*" mode="insert.direction.markup">
  <xsl:param name="purpose"/>
  <xsl:param name="xrefstyle"/>
  <xsl:param name="direction"/>

  <xsl:copy-of select="$direction"/>
</xsl:template>

<xsl:template match="*" mode="insert.title.markup">
  <xsl:param name="purpose"/>
  <xsl:param name="xrefstyle"/>
  <xsl:param name="title"/>

  <xsl:copy-of select="$title"/>

</xsl:template>

<xsl:template match="h:section[contains(@data-type, 'chapter') or contains(@data-type, 'appendix')]" mode="insert.title.markup">
  <xsl:param name="purpose"/>
  <xsl:param name="xrefstyle"/>
  <xsl:param name="title"/>

  <xsl:choose>
    <xsl:when test="$purpose = 'xref'">
      <em xmlns:xslo="http://www.w3.org/1999/XSL/Transform">
        <xsl:copy-of select="$title"/>
      </em>
    </xsl:when>
    <xsl:otherwise>
      <xsl:copy-of select="$title"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<!-- ============================================================ -->

<!-- Adapted from docbook-xsl common/l10.xsl stylesheet -->
<xsl:template name="gentext.template.exists">
  <xsl:param name="context" select="'default'"/>
  <xsl:param name="name" select="'default'"/>
  <xsl:param name="purpose"/>
  <xsl:param name="xrefstyle"/>
  <xsl:param name="referrer"/>
  <xsl:param name="lang" select="$book-language"/>

  <xsl:variable name="template">
    <xsl:call-template name="gentext.template">
      <xsl:with-param name="context" select="$context"/>
      <xsl:with-param name="name" select="$name"/>
      <xsl:with-param name="purpose" select="$purpose"/>
      <xsl:with-param name="xrefstyle" select="$xrefstyle"/>
      <xsl:with-param name="referrer" select="$referrer"/>
      <xsl:with-param name="lang" select="$lang"/>
      <xsl:with-param name="verbose" select="0"/>
    </xsl:call-template>
  </xsl:variable>
  
  <xsl:choose>
    <xsl:when test="string-length($template) != 0">1</xsl:when>
    <xsl:otherwise>0</xsl:otherwise>
  </xsl:choose>
</xsl:template>

<!-- ============================================================ -->

<!-- Adapted from docbook-xsl common/l10.xsl stylesheet -->
<!-- ENORMOUSLY simplifying the logic here -->
<xsl:template name="gentext.template">
  <xsl:param name="context" select="'default'"/>
  <xsl:param name="name" select="'default'"/>
  <xsl:param name="purpose"/>
  <xsl:param name="xrefstyle"/>
  <xsl:param name="referrer"/>
  <xsl:param name="lang" select="$book-language"/>
  <xsl:param name="verbose" select="1"/>

  <xsl:variable name="localizations-nodes" select="exsl:node-set($localizations)"/>

  <xsl:variable name="context.node"
		select="$localizations-nodes//l:l10n/l:context[@name=$context][1]"/>

  <xsl:if test="count($context.node) = 0
		and $verbose != 0">
    <xsl:call-template name="log-message">
      <xsl:with-param name="type" select="'DEBUG'"/>
      <xsl:with-param name="message">
	<xsl:text>No context named "</xsl:text>
	<xsl:value-of select="$context"/>
	<xsl:text>" exists in the "</xsl:text>
	<xsl:value-of select="$lang"/>
	<xsl:text>" localization.</xsl:text>    
      </xsl:with-param>
    </xsl:call-template>
  </xsl:if>

  <xsl:choose>
    <!-- If there's an $xrefstyle specified, first check for matching template @name and @style -->
    <xsl:when test="$xrefstyle != '' and $context.node/l:template[@name=$name and @style=$xrefstyle and @text]">
      <xsl:value-of select="$context.node/l:template[@name=$name and @style=$xrefstyle and @text][1]/@text"/>
    </xsl:when>
    <!-- If no $xrefstyle, just chekc for matching template @name -->
    <xsl:when test="$context.node/l:template[@name=$name and @text]">
      <xsl:value-of select="$context.node/l:template[@name=$name and @text][1]/@text"/>
    </xsl:when>
    <xsl:when test="$verbose = 0">
      <!-- silence -->
    </xsl:when>
    <xsl:otherwise>
      <xsl:call-template name="log-message">
	<xsl:with-param name="type" select="'DEBUG'"/>
	<xsl:with-param name="message">
	  <xsl:text>No template for "</xsl:text>
	  <xsl:value-of select="$name"/>
	  <xsl:text>" (or any of its leaves) exists in the context named "</xsl:text>
	  <xsl:value-of select="$context"/>
	  <xsl:text>" in the "</xsl:text>
	  <xsl:value-of select="$lang"/>
	  <xsl:text>" localization.</xsl:text>
	</xsl:with-param>
      </xsl:call-template>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

</xsl:stylesheet> 
