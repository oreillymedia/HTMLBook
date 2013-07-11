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
		xmlns="http://www.daisy.org/z3986/2005/ncx/"
		extension-element-prefixes="exsl func set date"
		exclude-result-prefixes="date e exsl func h htmlbook m ncx opf set svg">

  <!-- Generate an NCX file from HTMLBook source. -->
  <xsl:template name="generate.ncx.toc">
    <xsl:variable name="full-ncx-filename">
      <xsl:call-template name="full-output-filename">
	<xsl:with-param name="output-filename" select="$ncx.toc.filename"/>
      </xsl:call-template>
    </xsl:variable>
    <exsl:document href="{$full-ncx-filename}" method="xml" encoding="UTF-8">
      <ncx version="2005-1">
	<head/>
      </ncx>
    </exsl:document>
  </xsl:template>

</xsl:stylesheet> 
