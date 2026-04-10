<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:x="http://www.jenitennison.com/xslt/xspec"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                exclude-result-prefixes="#all"
                version="3.0">

   <!--
      Gathers all the children of the initial and the imported x:description. Mostly x:scenario but
      also the other children including x:variable and comments. (x:import is resolved and then
      discarded.)
      The original node identities, document URI and base URI are lost.
   -->
   <xsl:function name="x:resolve-import" as="node()*">
      <xsl:param name="initial-description" as="element(x:description)" />

      <!-- Collect all the instances of x:description by resolving x:import -->
      <xsl:variable name="descriptions" as="element(x:description)+"
         select="x:gather-descriptions($initial-description)" />

      <!-- Collect and resolve all the children of x:description -->
      <xsl:apply-templates select="$descriptions" mode="x:gather-specs" />
   </xsl:function>

   <!--
      Sub modules
   -->
   <xsl:include href="gather/gather-descriptions.xsl" />
   <xsl:include href="gather/gather-specs.xsl" />

</xsl:stylesheet>
