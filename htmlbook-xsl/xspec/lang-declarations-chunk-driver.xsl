<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:h="http://www.w3.org/1999/xhtml"
                xmlns:t="https://github.com/oreillymedia/HTMLBook/xspec-test"
                xmlns="http://www.w3.org/1999/xhtml"
                exclude-result-prefixes="h t">

  <!-- Test driver for lang-declarations-chunk.xspec. Imports chunk.xsl
       (not epub.xsl) so the tests exercise chunk.xsl's own
       process-content-for-chunk, which does not declare the epub
       namespace. Sidesteps the same xspec 0.4 <x:call>+<x:context>
       compiler bug worked around in lang-declarations-epub-driver.xsl.
       Remove this file when these tests move into chunk.xspec. -->

  <xsl:import href="../chunk.xsl"/>

  <xsl:output method="xml" encoding="UTF-8"/>

  <xsl:template match="t:chunk-trigger">
    <xsl:call-template name="process-content-for-chunk"/>
  </xsl:template>

</xsl:stylesheet>
