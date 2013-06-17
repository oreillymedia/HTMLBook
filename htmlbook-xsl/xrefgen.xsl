<xsl:stylesheet version="1.0"
		xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns:h="http://www.w3.org/1999/xhtml"
		xmlns="http://www.w3.org/1999/xhtml"
		exclude-result-prefixes="h">

  <xsl:output method="xml"
              encoding="UTF-8"/>
  <xsl:preserve-space elements="*"/>

  <!-- Default rule for TOC generation -->

  <!-- All XREFs must be tagged with a @class containing XREF -->
  <xsl:template match="h:a[contains(@class, 'xref')]">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
	<xsl:choose>
	  <!-- Generate XREF text node if <a> is either empty or $xref-placeholder-overwrite-contents = 1 -->
	  <xsl:when test="$autogenerate-xrefs = 1 and (. = '' or $xref-placeholder-overwrite-contents = 1)">
	    <xsl:apply-templates select="." mode="xref-to"/>
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
<xsl:template match="*" mode="object.xref.markup">
  <xsl:param name="purpose"/>
  <xsl:param name="xrefstyle"/>
  <xsl:param name="referrer"/>
  <xsl:param name="verbose" select="1"/>

  <xsl:variable name="template">
    <xsl:choose>
      <xsl:when test="starts-with(normalize-space($xrefstyle), 'select:')">
        <xsl:call-template name="make.gentext.template">
          <xsl:with-param name="xrefstyle" select="$xrefstyle"/>
          <xsl:with-param name="purpose" select="$purpose"/>
          <xsl:with-param name="referrer" select="$referrer"/>
        </xsl:call-template>
      </xsl:when>
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

<!-- 
  <xsl:message>
    <xsl:text>object.xref.markup: </xsl:text>
    <xsl:value-of select="local-name(.)"/>
    <xsl:text>(</xsl:text>
    <xsl:value-of select="$xrefstyle"/>
    <xsl:text>, </xsl:text>
    <xsl:value-of select="$purpose"/>
    <xsl:text>)</xsl:text>
    <xsl:text>: [</xsl:text>
    <xsl:value-of select="$template"/>
    <xsl:text>]</xsl:text>
  </xsl:message>
-->

  <xsl:if test="$template = '' and $verbose != 0">
    <xsl:message>
      <xsl:text>object.xref.markup: empty xref template</xsl:text>
      <xsl:text> for linkend="</xsl:text>
      <xsl:value-of select="@id|@xml:id"/>
      <xsl:text>" and @xrefstyle="</xsl:text>
      <xsl:value-of select="$xrefstyle"/>
      <xsl:text>"</xsl:text>
    </xsl:message>
  </xsl:if>

  <xsl:call-template name="substitute-markup">
    <xsl:with-param name="purpose" select="$purpose"/>
    <xsl:with-param name="xrefstyle" select="$xrefstyle"/>
    <xsl:with-param name="referrer" select="$referrer"/>
    <xsl:with-param name="template" select="$template"/>
    <xsl:with-param name="verbose" select="$verbose"/>
  </xsl:call-template>
</xsl:template>

<!-- ============================================================ -->

<xsl:template name="make.gentext.template">
  <xsl:param name="xrefstyle" select="''"/>
  <xsl:param name="purpose"/>
  <xsl:param name="referrer"/>
  <xsl:param name="lang">
    <xsl:call-template name="l10n.language"/>
  </xsl:param>
  <xsl:param name="target.elem" select="local-name(.)"/>

  <!-- parse xrefstyle to get parts -->
  <xsl:variable name="parts"
      select="substring-after(normalize-space($xrefstyle), 'select:')"/>

  <xsl:variable name="labeltype">
    <xsl:choose>
      <xsl:when test="contains($parts, 'labelnumber')">
         <xsl:text>labelnumber</xsl:text>
      </xsl:when>
      <xsl:when test="contains($parts, 'labelname')">
         <xsl:text>labelname</xsl:text>
      </xsl:when>
      <xsl:when test="contains($parts, 'label')">
         <xsl:text>label</xsl:text>
      </xsl:when>
    </xsl:choose>
  </xsl:variable>

  <xsl:variable name="titletype">
    <xsl:choose>
      <xsl:when test="contains($parts, 'quotedtitle')">
         <xsl:text>quotedtitle</xsl:text>
      </xsl:when>
      <xsl:when test="contains($parts, 'title')">
         <xsl:text>title</xsl:text>
      </xsl:when>
    </xsl:choose>
  </xsl:variable>

  <xsl:variable name="pagetype">
    <xsl:choose>
      <xsl:when test="$insert.olink.page.number = 'no' and
                      local-name($referrer) = 'olink'">
        <!-- suppress page numbers -->
      </xsl:when>
      <xsl:when test="$insert.xref.page.number = 'no' and
                      local-name($referrer) != 'olink'">
        <!-- suppress page numbers -->
      </xsl:when>
      <xsl:when test="contains($parts, 'nopage')">
         <xsl:text>nopage</xsl:text>
      </xsl:when>
      <xsl:when test="contains($parts, 'pagenumber')">
         <xsl:text>pagenumber</xsl:text>
      </xsl:when>
      <xsl:when test="contains($parts, 'pageabbrev')">
         <xsl:text>pageabbrev</xsl:text>
      </xsl:when>
      <xsl:when test="contains($parts, 'Page')">
         <xsl:text>Page</xsl:text>
      </xsl:when>
      <xsl:when test="contains($parts, 'page')">
         <xsl:text>page</xsl:text>
      </xsl:when>
    </xsl:choose>
  </xsl:variable>

  <xsl:variable name="docnametype">
    <xsl:choose>
      <xsl:when test="($olink.doctitle = 0 or
                       $olink.doctitle = 'no') and
                      local-name($referrer) = 'olink'">
        <!-- suppress docname -->
      </xsl:when>
      <xsl:when test="contains($parts, 'nodocname')">
         <xsl:text>nodocname</xsl:text>
      </xsl:when>
      <xsl:when test="contains($parts, 'docnamelong')">
         <xsl:text>docnamelong</xsl:text>
      </xsl:when>
      <xsl:when test="contains($parts, 'docname')">
         <xsl:text>docname</xsl:text>
      </xsl:when>
    </xsl:choose>
  </xsl:variable>

  <xsl:if test="$labeltype != ''">
    <xsl:choose>
      <xsl:when test="$labeltype = 'labelname'">
        <xsl:call-template name="gentext">
          <xsl:with-param name="key">
            <xsl:choose>
              <xsl:when test="local-name($referrer) = 'olink'">
                <xsl:value-of select="$target.elem"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="local-name(.)"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:with-param>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="$labeltype = 'labelnumber'">
        <xsl:text>%n</xsl:text>
      </xsl:when>
      <xsl:when test="$labeltype = 'label'">
        <xsl:call-template name="gentext.template">
          <xsl:with-param name="context" select="'xref-number'"/>
          <xsl:with-param name="name">
            <xsl:choose>
              <xsl:when test="local-name($referrer) = 'olink'">
                <xsl:value-of select="$target.elem"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:call-template name="xpath.location"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:with-param>
          <xsl:with-param name="purpose" select="$purpose"/>
          <xsl:with-param name="xrefstyle" select="$xrefstyle"/>
          <xsl:with-param name="referrer" select="$referrer"/>
        </xsl:call-template>
      </xsl:when>
    </xsl:choose>

    <xsl:choose>
      <xsl:when test="$titletype != ''">
        <xsl:value-of select="$xref.label-title.separator"/>
      </xsl:when>
      <xsl:when test="$pagetype != '' and $pagetype != 'nopage'">
        <xsl:value-of select="$xref.label-page.separator"/>
      </xsl:when>
    </xsl:choose>
  </xsl:if>

  <xsl:if test="$titletype != ''">
    <xsl:choose>
      <xsl:when test="$titletype = 'title'">
        <xsl:text>%t</xsl:text>
      </xsl:when>
      <xsl:when test="$titletype = 'quotedtitle'">
        <xsl:call-template name="gentext.dingbat">
          <xsl:with-param name="dingbat" select="'startquote'"/>
        </xsl:call-template>
        <xsl:text>%t</xsl:text>
        <xsl:call-template name="gentext.dingbat">
          <xsl:with-param name="dingbat" select="'endquote'"/>
        </xsl:call-template>
      </xsl:when>
    </xsl:choose>

    <xsl:choose>
      <xsl:when test="$pagetype != '' and $pagetype != 'nopage'">
        <xsl:value-of select="$xref.title-page.separator"/>
      </xsl:when>
    </xsl:choose>
  </xsl:if>
  
  <!-- special case: use regular xref template if just turning off page -->
  <xsl:if test="($pagetype = 'nopage' or $docnametype = 'nodocname')
                  and local-name($referrer) != 'olink'
                  and $labeltype = '' 
                  and $titletype = ''">
    <xsl:apply-templates select="." mode="object.xref.template">
      <xsl:with-param name="purpose" select="$purpose"/>
      <xsl:with-param name="xrefstyle" select="$xrefstyle"/>
      <xsl:with-param name="referrer" select="$referrer"/>
    </xsl:apply-templates>
  </xsl:if>

  <xsl:if test="$pagetype != ''">
    <xsl:choose>
      <xsl:when test="$pagetype = 'page'">
        <xsl:call-template name="gentext.template">
          <xsl:with-param name="context" select="'xref'"/>
          <xsl:with-param name="name" select="'page'"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="$pagetype = 'Page'">
        <xsl:call-template name="gentext.template">
          <xsl:with-param name="context" select="'xref'"/>
          <xsl:with-param name="name" select="'Page'"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="$pagetype = 'pageabbrev'">
        <xsl:call-template name="gentext.template">
          <xsl:with-param name="context" select="'xref'"/>
          <xsl:with-param name="name" select="'pageabbrev'"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="$pagetype = 'pagenumber'">
        <xsl:text>%p</xsl:text>
      </xsl:when>
    </xsl:choose>

  </xsl:if>

  <!-- Add reference to other document title -->
  <xsl:if test="$docnametype != '' and local-name($referrer) = 'olink'">
    <!-- Any separator should be in the gentext template -->
    <xsl:choose>
      <xsl:when test="$docnametype = 'docnamelong'">
        <xsl:call-template name="gentext.template">
          <xsl:with-param name="context" select="'xref'"/>
          <xsl:with-param name="name" select="'docnamelong'"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="$docnametype = 'docname'">
        <xsl:call-template name="gentext.template">
          <xsl:with-param name="context" select="'xref'"/>
          <xsl:with-param name="name" select="'docname'"/>
        </xsl:call-template>
      </xsl:when>
    </xsl:choose>

  </xsl:if>
  
</xsl:template>

<!-- ============================================================ -->

<xsl:template match="*" mode="object.xref.template">
  <xsl:param name="purpose"/>
  <xsl:param name="xrefstyle"/>
  <xsl:param name="referrer"/>

  <!-- Is autonumbering on? -->
  <xsl:variable name="autonumber">
    <xsl:apply-templates select="." mode="is.autonumber"/>
  </xsl:variable>

  <xsl:variable name="number-and-title-template">
    <xsl:call-template name="gentext.template.exists">
      <xsl:with-param name="context" select="'xref-number-and-title'"/>
      <xsl:with-param name="name">
        <xsl:call-template name="xpath.location"/>
      </xsl:with-param>
    </xsl:call-template>
  </xsl:variable>

  <xsl:variable name="number-template">
    <xsl:call-template name="gentext.template.exists">
      <xsl:with-param name="context" select="'xref-number'"/>
      <xsl:with-param name="name">
        <xsl:call-template name="xpath.location"/>
      </xsl:with-param>
    </xsl:call-template>
  </xsl:variable>

  <xsl:variable name="context">
    <xsl:choose>
      <xsl:when test="self::equation and not(title) and not(info/title)">
         <xsl:value-of select="'xref-number'"/>
      </xsl:when>
      <xsl:when test="string($autonumber) != 0 
                      and $number-and-title-template != 0
                      and $xref.with.number.and.title != 0">
         <xsl:value-of select="'xref-number-and-title'"/>
      </xsl:when>
      <xsl:when test="string($autonumber) != 0 
                      and $number-template != 0">
         <xsl:value-of select="'xref-number'"/>
      </xsl:when>
      <xsl:otherwise>
         <xsl:value-of select="'xref'"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:call-template name="gentext.template">
    <xsl:with-param name="context" select="$context"/>
    <xsl:with-param name="name">
      <xsl:call-template name="xpath.location"/>
    </xsl:with-param>
    <xsl:with-param name="purpose" select="$purpose"/>
    <xsl:with-param name="xrefstyle" select="$xrefstyle"/>
    <xsl:with-param name="referrer" select="$referrer"/>
  </xsl:call-template>

</xsl:template>

<!-- ============================================================ -->

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
        <xsl:when test="$candidate = 's'">
          <xsl:apply-templates select="." mode="insert.subtitle.markup">
            <xsl:with-param name="purpose" select="$purpose"/>
            <xsl:with-param name="xrefstyle" select="$xrefstyle"/>
            <xsl:with-param name="subtitle">
              <xsl:choose>
                <xsl:when test="$subtitle != ''">
                  <xsl:copy-of select="$subtitle"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:apply-templates select="." mode="subtitle.markup">
                    <xsl:with-param name="allow-anchors" select="$allow-anchors"/>
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
        <xsl:when test="$candidate = 'p'">
          <xsl:apply-templates select="." mode="insert.pagenumber.markup">
            <xsl:with-param name="purpose" select="$purpose"/>
            <xsl:with-param name="xrefstyle" select="$xrefstyle"/>
            <xsl:with-param name="pagenumber">
              <xsl:choose>
                <xsl:when test="$pagenumber != ''">
                  <xsl:copy-of select="$pagenumber"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:apply-templates select="." mode="pagenumber.markup"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:with-param>
          </xsl:apply-templates>
        </xsl:when>
        <xsl:when test="$candidate = 'o'">
          <!-- olink target document title -->
          <xsl:apply-templates select="." mode="insert.olink.docname.markup">
            <xsl:with-param name="purpose" select="$purpose"/>
            <xsl:with-param name="xrefstyle" select="$xrefstyle"/>
            <xsl:with-param name="docname">
              <xsl:choose>
                <xsl:when test="$docname != ''">
                  <xsl:copy-of select="$docname"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:apply-templates select="." mode="olink.docname.markup"/>
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
                    <xsl:for-each select="preceding::xref">
                      <xsl:if test="generate-id(.) = generate-id($referrer)">1</xsl:if>
                    </xsl:for-each>
                  </xsl:variable>
                  <xsl:choose>
                    <xsl:when test="$referent-is-below = ''">
                      <xsl:call-template name="gentext">
                        <xsl:with-param name="key" select="'above'"/>
                      </xsl:call-template>
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:call-template name="gentext">
                        <xsl:with-param name="key" select="'below'"/>
                      </xsl:call-template>
                    </xsl:otherwise>
                  </xsl:choose>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:message>Attempt to use %d in gentext with no referrer!</xsl:message>
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

<!-- Adapted from docbook-xsl common/l10.xsl stylesheet -->
<xsl:template name="gentext.template.exists">
  <xsl:param name="context" select="'default'"/>
  <xsl:param name="name" select="'default'"/>
  <xsl:param name="origname" select="$name"/>
  <xsl:param name="purpose"/>
  <xsl:param name="xrefstyle"/>
  <xsl:param name="referrer"/>
  <xsl:param name="lang">
    <xsl:call-template name="l10n.language"/>
  </xsl:param>

  <xsl:variable name="template">
    <xsl:call-template name="gentext.template">
      <xsl:with-param name="context" select="$context"/>
      <xsl:with-param name="name" select="$name"/>
      <xsl:with-param name="origname" select="$origname"/>
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
<xsl:template name="gentext.template">
  <xsl:param name="context" select="'default'"/>
  <xsl:param name="name" select="'default'"/>
  <xsl:param name="origname" select="$name"/>
  <xsl:param name="purpose"/>
  <xsl:param name="xrefstyle"/>
  <xsl:param name="referrer"/>
  <xsl:param name="lang">
    <xsl:call-template name="l10n.language"/>
  </xsl:param>
  <xsl:param name="verbose" select="1"/>

  <xsl:choose>
    <xsl:when test="$empty.local.l10n.xml">
      <xsl:for-each select="$l10n.xml">  <!-- We need to switch context in order to make key() work -->
	<xsl:for-each select="document(key('l10n-lang', $lang)/@href)">

	  <xsl:variable name="localization.node"
			select="key('l10n-lang', $lang)[1]"/>

	  <xsl:if test="count($localization.node) = 0
			and $verbose != 0">
	    <xsl:message>
	      <xsl:text>No "</xsl:text>
	      <xsl:value-of select="$lang"/>
	      <xsl:text>" localization exists.</xsl:text>
	    </xsl:message>
	  </xsl:if>

	  <xsl:variable name="context.node"
			select="key('l10n-context', $context)[1]"/>

	  <xsl:if test="count($context.node) = 0
			and $verbose != 0">
	    <xsl:message>
	      <xsl:text>No context named "</xsl:text>
	      <xsl:value-of select="$context"/>
	      <xsl:text>" exists in the "</xsl:text>
	      <xsl:value-of select="$lang"/>
	      <xsl:text>" localization.</xsl:text>
	    </xsl:message>
	  </xsl:if>

	  <xsl:for-each select="$context.node">
	    <xsl:variable name="template.node"
			  select="(key('l10n-template-style', concat($context, '#', $name, '#', $xrefstyle))
				   |key('l10n-template', concat($context, '#', $name)))[1]"/>

	    <xsl:choose>
	      <xsl:when test="$template.node/@text">
		<xsl:value-of select="$template.node/@text"/>
	      </xsl:when>
	      <xsl:otherwise>
		<xsl:choose>
		  <xsl:when test="contains($name, '/')">
		    <xsl:call-template name="gentext.template">
		      <xsl:with-param name="context" select="$context"/>
		      <xsl:with-param name="name" select="substring-after($name, '/')"/>
		      <xsl:with-param name="origname" select="$origname"/>
		      <xsl:with-param name="purpose" select="$purpose"/>
		      <xsl:with-param name="xrefstyle" select="$xrefstyle"/>
		      <xsl:with-param name="referrer" select="$referrer"/>
		      <xsl:with-param name="lang" select="$lang"/>
		      <xsl:with-param name="verbose" select="$verbose"/>
		    </xsl:call-template>
		  </xsl:when>
		  <xsl:when test="$verbose = 0">
		    <!-- silence -->
		  </xsl:when>
		  <xsl:otherwise>
		    <xsl:message>
		      <xsl:text>No template for "</xsl:text>
		      <xsl:value-of select="$origname"/>
		      <xsl:text>" (or any of its leaves) exists in the context named "</xsl:text>
		      <xsl:value-of select="$context"/>
		      <xsl:text>" in the "</xsl:text>
		      <xsl:value-of select="$lang"/>
		      <xsl:text>" localization.</xsl:text>
		    </xsl:message>
		  </xsl:otherwise>
		</xsl:choose>
	      </xsl:otherwise>
	    </xsl:choose>
	  </xsl:for-each>
	</xsl:for-each>
      </xsl:for-each>
    </xsl:when>
    <xsl:otherwise>
      <xsl:for-each select="$l10n.xml">  <!-- We need to switch context in order to make key() work -->
	<xsl:for-each select="document(key('l10n-lang', $lang)/@href)">

	  <xsl:variable name="local.localization.node"
			select="($local.l10n.xml//l:i18n/l:l10n[@language=$lang])[1]"/>

	  <xsl:variable name="localization.node"
			select="key('l10n-lang', $lang)[1]"/>

	  <xsl:if test="count($localization.node) = 0
			and count($local.localization.node) = 0
			and $verbose != 0">
	    <xsl:message>
	      <xsl:text>No "</xsl:text>
	      <xsl:value-of select="$lang"/>
	      <xsl:text>" localization exists.</xsl:text>
	    </xsl:message>
	  </xsl:if>

	  <xsl:variable name="local.context.node"
			select="$local.localization.node/l:context[@name=$context]"/>

	  <xsl:variable name="context.node"
			select="key('l10n-context', $context)[1]"/>

	  <xsl:if test="count($context.node) = 0
			and count($local.context.node) = 0
			and $verbose != 0">
	    <xsl:message>
	      <xsl:text>No context named "</xsl:text>
	      <xsl:value-of select="$context"/>
	      <xsl:text>" exists in the "</xsl:text>
	      <xsl:value-of select="$lang"/>
	      <xsl:text>" localization.</xsl:text>
	    </xsl:message>
	  </xsl:if>

	  <xsl:variable name="local.template.node"
			select="($local.context.node/l:template[@name=$name
								and @style
								and @style=$xrefstyle]
				|$local.context.node/l:template[@name=$name
								and not(@style)])[1]"/>

	  <xsl:for-each select="$context.node">
	    <xsl:variable name="template.node"
			  select="(key('l10n-template-style', concat($context, '#', $name, '#', $xrefstyle))
				   |key('l10n-template', concat($context, '#', $name)))[1]"/>

	    <xsl:choose>
	      <xsl:when test="$local.template.node/@text">
		<xsl:value-of select="$local.template.node/@text"/>
	      </xsl:when>
	      <xsl:when test="$template.node/@text">
		<xsl:value-of select="$template.node/@text"/>
	      </xsl:when>
	      <xsl:otherwise>
		<xsl:choose>
		  <xsl:when test="contains($name, '/')">
		    <xsl:call-template name="gentext.template">
		      <xsl:with-param name="context" select="$context"/>
		      <xsl:with-param name="name" select="substring-after($name, '/')"/>
		      <xsl:with-param name="origname" select="$origname"/>
		      <xsl:with-param name="purpose" select="$purpose"/>
		      <xsl:with-param name="xrefstyle" select="$xrefstyle"/>
		      <xsl:with-param name="referrer" select="$referrer"/>
		      <xsl:with-param name="lang" select="$lang"/>
		      <xsl:with-param name="verbose" select="$verbose"/>
		    </xsl:call-template>
		  </xsl:when>
		  <xsl:when test="$verbose = 0">
		    <!-- silence -->
		  </xsl:when>
		  <xsl:otherwise>
		    <xsl:message>
		      <xsl:text>No template for "</xsl:text>
		      <xsl:value-of select="$origname"/>
		      <xsl:text>" (or any of its leaves) exists in the context named "</xsl:text>
		      <xsl:value-of select="$context"/>
		      <xsl:text>" in the "</xsl:text>
		      <xsl:value-of select="$lang"/>
		      <xsl:text>" localization.</xsl:text>
		    </xsl:message>
		  </xsl:otherwise>
		</xsl:choose>
	      </xsl:otherwise>
	    </xsl:choose>
	  </xsl:for-each>
	</xsl:for-each>
      </xsl:for-each>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

</xsl:stylesheet> 
