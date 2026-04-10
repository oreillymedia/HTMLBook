<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0" xmlns:local="urn:x-xspec:compiler:xproc:compile:get-step-inputs:local"
    xmlns:p="http://www.w3.org/ns/xproc" xmlns:x="http://www.jenitennison.com/xslt/xspec"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    exclude-result-prefixes="#all">

    <!-- Global variables -->
    <xsl:variable name="xproc-doc-uri" as="xs:anyURI"
        select="$initial-document/x:description/@xproc ! resolve-uri(string(.), base-uri(.))"/>
    <xsl:variable name="xproc-doc" as="document-node()" select="doc($xproc-doc-uri)"/>
    <xsl:variable name="xproc-input-tree" as="document-node()">
        <xsl:document>
            <p:library>
                <xsl:apply-templates select="$xproc-doc" mode="local:gather-steps">
                    <xsl:with-param name="import-stack" tunnel="yes" select="$xproc-doc-uri"/>
                </xsl:apply-templates>        
            </p:library>
        </xsl:document>
    </xsl:variable>

    <!-- Keys -->
    <xsl:key name="step-declarations" match="p:declare-step[@type]" use="string(@type)"/>
    <xsl:key name="static-library-options" match="p:library/p:option" use="x:UQName-from-EQName-ignoring-default-ns(@name, .)"/>

    <!-- Functions -->
    <xsl:function name="x:step-declaration" as="element(p:declare-step)">
        <xsl:param name="x-call" as="element(x:call)"/>
        <xsl:param name="parent-scenario" as="element(x:scenario)"/>
        <xsl:variable name="step-UQName" as="xs:string" select="x:UQName-of-step($x-call/@step)"/>
        <xsl:variable name="p-declare-step" as="element(p:declare-step)*"
            select="key('step-declarations', $step-UQName, $xproc-input-tree)[1]"/>
        <xsl:if test="empty($p-declare-step)">
            <xsl:for-each select="$parent-scenario/x:call">
                <xsl:message terminate="yes">
                    <xsl:call-template name="x:prefix-diag-message">
                        <xsl:with-param name="message">
                            <xsl:text expand-text="yes">Cannot find step { $step-UQName }.</xsl:text>
                        </xsl:with-param>
                    </xsl:call-template>
                </xsl:message>
            </xsl:for-each>
        </xsl:if>
        <xsl:sequence select="$p-declare-step"/>
    </xsl:function>

    <xsl:function name="x:UQName-of-step" as="xs:string">
        <xsl:param name="attr" as="attribute()"/>
        <!-- $attr is p:declare-step/@type or x:call/@step -->
        <xsl:choose>
            <xsl:when test="contains($attr, ':')">
                <xsl:sequence select="x:UQName-from-EQName-ignoring-default-ns($attr, $attr/..)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="$attr/string()"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <!-- Templates -->

    <!-- local:gather-steps mode -->
    <xsl:mode name="local:gather-steps" on-no-match="shallow-skip"/>
    <xsl:template match="document-node()" mode="local:gather-steps" as="element()*">
        <xsl:param name="import-stack" tunnel="yes" required="yes" as="xs:anyURI*"/>
        <xsl:apply-templates mode="#current">
            <xsl:with-param name="import-stack" tunnel="yes" select="$import-stack"/>
        </xsl:apply-templates>
    </xsl:template>
    <xsl:template match="/p:library" mode="local:gather-steps">
        <xsl:apply-templates select="(p:option, p:declare-step[@type], p:import)" mode="#current"/>
    </xsl:template>
    <xsl:template match="p:declare-step[@visibility eq 'private']" mode="local:gather-steps">
        <!-- Skip private steps -->
    </xsl:template>
    <xsl:template match="p:declare-step[not(@visibility eq 'private')]" mode="local:gather-steps">
        <xsl:copy>
            <xsl:attribute name="type" select="x:UQName-of-step(./@type)"/>
            <xsl:sequence select="@use-when"/>
            <xsl:apply-templates select="p:input | p:output | p:option" mode="#current"/>
        </xsl:copy>
        <xsl:apply-templates select="p:import" mode="#current"/>
    </xsl:template>
    <xsl:template match="p:input | p:output" mode="local:gather-steps">
        <xsl:copy>
            <xsl:sequence select="@port | @use-when"/>
            <xsl:if test="exists(self::p:input/*) or exists(self::p:input/@href)">
                <xsl:attribute name="x:has-default-input" select="'true'"/>    
            </xsl:if>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="p:option" mode="local:gather-steps">
        <xsl:copy>
            <xsl:sequence select="@name | @static"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="p:import[@href]" mode="local:gather-steps">
        <xsl:param name="import-stack" tunnel="yes" required="yes" as="xs:anyURI*"/>
        <!-- We might import the same pipeline multiple times, but non-circular duplication doesn't
            matter for later processing. Alternatively, we could remove duplicates by imitating the
            compiler's x:gather-descriptions function. -->
        <xsl:variable name="resolved-href" as="xs:anyURI?"
            select="resolve-uri(@href, x:base-uri(.)) => x:resolve-xml-uri-with-catalog()"/>
        <xsl:if test="not($resolved-href = $import-stack)">
            <xsl:apply-templates select="$resolved-href => doc()" mode="#current">
                <xsl:with-param name="import-stack" tunnel="yes"
                    select="($resolved-href, $import-stack)"/>
            </xsl:apply-templates>
        </xsl:if>
    </xsl:template>

</xsl:stylesheet>
