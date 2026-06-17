<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:h="http://www.w3.org/1999/xhtml"
                xmlns:t="https://github.com/oreillymedia/HTMLBook/xspec-test"
                xmlns="http://www.w3.org/1999/xhtml"
                exclude-result-prefixes="h t">

  <!-- Test driver for lang-declarations-epub.xspec. Imports epub.xsl so
       tests can reach its templates, and exposes process-content-for-chunk
       via a match template on a custom element. This sidesteps a bug in
       xspec 0.4 where <x:call> combined with <x:context> generates an
       undeclared $context variable. Remove this file when those tests move
       to epub.xspec. -->

  <xsl:import href="../epub.xsl"/>

  <xsl:output method="xml" encoding="UTF-8"/>

  <!-- Match a custom trigger element and route it through
       process-content-for-chunk. The trigger's namespace keeps it from
       colliding with any existing match patterns in the imported chain. -->
  <xsl:template match="t:chunk-trigger">
    <xsl:call-template name="process-content-for-chunk"/>
  </xsl:template>

  <!-- Routes a cover trigger element through cover-html-document so
       XSpec can assert on the generated <html> node. -->
  <xsl:template match="t:cover-trigger">
    <xsl:call-template name="cover-html-document"/>
  </xsl:template>

</xsl:stylesheet>
