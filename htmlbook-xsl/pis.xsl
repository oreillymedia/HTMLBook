<xsl:stylesheet version="1.0"
		xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns:exsl="http://exslt.org/common"
		xmlns:h="http://www.w3.org/1999/xhtml"
		xmlns="http://www.w3.org/1999/xhtml"
		extension-element-prefixes="exsl"
		exclude-result-prefixes="exsl h">

  <!-- Templates for Processing Instruction handling/functionality -->

  <xsl:output method="xml"
              encoding="UTF-8"/>
  <xsl:preserve-space elements="*"/>

  <xsl:template match="processing-instruction()[contains(name(), 'pagebreak')]"> 
    <div class="{name()}" />
  </xsl:template>

</xsl:stylesheet> 
