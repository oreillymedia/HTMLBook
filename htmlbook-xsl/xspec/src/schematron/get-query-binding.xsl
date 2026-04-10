<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:sch="http://purl.oclc.org/dsdl/schematron"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" exclude-result-prefixes="#all" version="3.0">
    <xsl:output method="text"/>
    <xsl:template name="xsl:initial-template" as="text()">
        <xsl:value-of select="
                doc(resolve-uri(/*/@schematron, base-uri(/*)))/sch:schema/@queryBinding
                ! replace(., '[0-9]+', '')"/>
    </xsl:template>
</xsl:stylesheet>
