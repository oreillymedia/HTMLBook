<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:impl="urn:x-xspec:compile:impl" xmlns:p="http://www.w3.org/ns/xproc"
    xmlns:x="http://www.jenitennison.com/xslt/xspec" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" exclude-result-prefixes="#all" version="3.0">

    <xsl:include href="../../../common/uri-utils.xsl"/>
    <xsl:include href="../../../common/uqname-utils.xsl"/>
    <xsl:include href="../../../common/common-utils.xsl"/>
    <xsl:include href="../../../common/namespace-vars.xsl"/>
    <xsl:include href="../../base/util/compiler-misc-utils.xsl"/>
    <xsl:include href="resolve-xproc-attribute.xsl"/>

    <xsl:variable name="initial-document" as="document-node(element(x:description))" select="/"/>

    <!-- Entry point from xspec.bat and xspec.sh -->
    <xsl:template match="/" as="element(p:library)">
        <p:library version="3.1">
            <xsl:call-template name="generate-imports"/>
            <xsl:call-template name="declare-step-runner"/>
        </p:library>
    </xsl:template>

    <!-- Entry point from generate-pipeline.xsl -->
    <xsl:template name="generate-imports" as="node()+">
        <xsl:context-item as="document-node(element(x:description))" use="required"/>
        <xsl:comment>Import a library that the test runner uses</xsl:comment>
        <xsl:call-template name="import-function-wrappers"/>
        <xsl:sequence>
            <xsl:on-non-empty>
                <xsl:comment select="'Import pipelines referenced by @xproc in x:helper, ' ||
                    'recursively across imported XSpec files'"/>
            </xsl:on-non-empty>
            <xsl:apply-templates select="x:description" mode="generate-imports"/>
        </xsl:sequence>       
    </xsl:template>

    <xsl:template name="declare-step-runner" as="element(p:declare-step)">
        <xsl:sequence select="doc(resolve-uri('../../../common/step-runner.xpl'))/*"/>
    </xsl:template>

    <xsl:template match="x:description" as="element(p:import)*" mode="generate-imports">
        <xsl:apply-templates select="x:helper" mode="#current"/>
        <xsl:for-each select="x:import[@href]">
            <xsl:variable name="imported-xspec" as="document-node(element(x:description))"
                select="@href => resolve-uri(base-uri()) => doc()"/>
            <xsl:apply-templates select="$imported-xspec/x:description" mode="#current"/>
        </xsl:for-each>
    </xsl:template>

    <xsl:template match="x:helper" as="element(p:import)?" mode="generate-imports">
        <xsl:apply-templates select="@xproc" mode="#current"/>
    </xsl:template>

    <xsl:template match="x:description/@xproc | x:helper/@xproc" as="element(p:import)"
        mode="generate-imports">
        <xsl:variable name="resolved-xproc-attribute" as="xs:anyURI">
            <xsl:apply-templates select="." mode="resolve-xproc-attribute"/>    
        </xsl:variable>
        <p:import href="{$resolved-xproc-attribute}"/>
    </xsl:template>

    <xsl:template name="import-function-wrappers" as="element(p:import)">
        <xsl:variable name="resolved-uri" select="
                resolve-uri('../wrap-standard-functions/wrap-standard-functions.xpl')"/>
        <p:import href="{$resolved-uri}"/>
    </xsl:template>
</xsl:stylesheet>
