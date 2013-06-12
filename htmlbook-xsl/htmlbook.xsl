<xsl:stylesheet version="1.0"
		xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns:h="http://www.w3.org/1999/xhtml"
		xmlns="http://www.w3.org/1999/xhtml">

  <!-- Master template that should be called directly to do tocgen, indexgen, and xrefgen as specified via params -->

  <!-- Imports common.xsl for common utility templates --> 
  <xsl:import href="common.xsl"/>

  <xsl:include href="idgen.xsl"/> <!-- Id decoration as needed for autogeneration of TOC/index -->
  <xsl:include href="tocgen.xsl"/> <!-- Autogeneration of TOC if specified in autogenerate-toc -->
  <xsl:include href="indexgen.xsl"/> <!-- Autogeneration of index if specified in autogenerate-index -->

  <xsl:output method="xml"
              encoding="UTF-8"/>
  <xsl:preserve-space elements="*"/>

  <xsl:param name="autogenerate-toc" select="1"/>
  <xsl:param name="autogenerate-index" select="1"/>

</xsl:stylesheet> 
