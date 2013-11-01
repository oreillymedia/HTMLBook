<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:functx="http://www.functx.com" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="xs" version="2.0">

    <!-- The functx:escape-for-regex function escapes a string that you wish to be taken 
         literally rather than treated like a regular expression. This is useful when, 
         for example, you are calling the built-in fn:replace function and you want any 
         periods or parentheses to be treated like literal characters rather than regex 
         special characters. 
         From: http://www.xsltfunctions.com/xsl/functx_escape-for-regex.html
    -->
    <xsl:function name="functx:escape-for-regex" as="xs:string">
        <xsl:param name="arg" as="xs:string?"/>

        <xsl:sequence
            select=" 
            replace($arg,
            '(\.|\[|\]|\\|\||\-|\^|\$|\?|\*|\+|\{|\}|\(|\))','\\$1')
            "
        />
    </xsl:function>


    <!-- Escape regexes in a list of phrases -->

    <xsl:template match="phrases">
        <phrases>
            <xsl:apply-templates select="phrase"/>
        </phrases>
    </xsl:template>

    <xsl:template match="phrase">
        <xsl:variable name="escaped-text" select="functx:escape-for-regex(.)"/>
        <phrase status="{if (. = $escaped-text) then 'changed' else 'same'}">
            <xsl:value-of select="functx:escape-for-regex(.)"/>
        </phrase>
    </xsl:template>

</xsl:stylesheet>
