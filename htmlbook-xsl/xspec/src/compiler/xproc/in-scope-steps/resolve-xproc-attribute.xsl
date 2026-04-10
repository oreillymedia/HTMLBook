<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:p="http://www.w3.org/ns/xproc"
    xmlns:x="http://www.jenitennison.com/xslt/xspec"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="#all" version="3.0">
    <xsl:template match="x:description/@xproc | x:helper/@xproc" mode="resolve-xproc-attribute"
        as="xs:anyURI?">
        <!-- Resolve @xproc to get actual base URI -->
        <xsl:variable name="resolved-xproc" as="xs:anyURI" select="
                resolve-uri(., base-uri())
                => x:resolve-xml-uri-with-catalog()"/>
        <xsl:choose>
            <xsl:when test="exists(doc($resolved-xproc)/(p:declare-step | p:library))">
                <xsl:sequence select="$resolved-xproc"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:for-each select="..">
                    <xsl:message terminate="yes">
                        <xsl:call-template name="x:prefix-diag-message">
                            <xsl:with-param name="message">
                                <xsl:text expand-text="yes">File at {@xproc} is not XProc. </xsl:text>
                                <xsl:text>It should have /p:declare-step or /p:library. </xsl:text>
                                <xsl:text expand-text="yes">Instead, it has /{
                                    doc($resolved-xproc)/element() => name()
                                    }.</xsl:text>
                            </xsl:with-param>
                        </xsl:call-template>
                    </xsl:message>
                </xsl:for-each>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
</xsl:stylesheet>