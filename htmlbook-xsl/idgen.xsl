<xsl:stylesheet version="1.0"
		xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns:h="http://www.w3.org/1999/xhtml"
		xmlns="http://www.w3.org/1999/xhtml">

<!-- Template for id decoration on elements that need it for TOC and/or index generation. 
     Should be at a lower import level than tocgen.xsl and indexgen.xsl, so that those
     templates can override id-generation templates to add additional functionality, if needed -->

  <xsl:output method="xml"
              encoding="UTF-8"/>
  <xsl:preserve-space elements="*"/>

  <!-- Elements that require ids: 
       * All <sections>
       * <div class="part">
       * All <a class="indexterm"> tags
    -->
  <!-- WARNING: If you need additional handling for these elements for other functionality,
       and you override this template elsewhere, make sure you add in id-decoration functionality -->
  <xsl:template match="h:section|h:div[@class='part']|h:a[@class='indexterm']">
    <xsl:copy>
      <xsl:apply-templates select="@*[not(local-name() = 'id')]"/>
      <xsl:attribute name="id">
	<xsl:call-template name="object.id"/>
      </xsl:attribute>
      <xsl:apply-templates/>      
    </xsl:copy>
  </xsl:template>    

</xsl:stylesheet> 
