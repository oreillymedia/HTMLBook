<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0" xmlns:p="http://www.w3.org/ns/xproc" xmlns:x="http://www.jenitennison.com/xslt/xspec"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

    <xsl:param name="xspec-home" as="xs:string" select="resolve-uri('../../../')"/>
    <xsl:param name="force-focus" as="xs:string?"/>
    <xsl:param name="html-report-theme" as="xs:string" select="'default'"/>
    <xsl:include href="../../compiler/xproc/in-scope-steps/generate-xproc-imports.xsl"/>

    <xsl:template name="generate-pipeline" as="element(p:declare-step)">
        <xsl:context-item as="document-node(element(x:description))" use="required"/>
        <p:declare-step version="3.1" xmlns:x="http://www.jenitennison.com/xslt/xspec">
            <xsl:call-template name="generate-imports"/>
            <xsl:call-template name="declare-ports"/>
            <xsl:call-template name="declare-step-runner"/>
            <xsl:call-template name="declare-harness-step"/>
            <xsl:call-template name="execute-harness-step"/>
        </p:declare-step>
    </xsl:template>

    <xsl:template name="declare-ports" as="node()+">
        <xsl:comment>Declare ports</xsl:comment>
        <p:input port="xspec"/>
        <p:output port="result"/>
    </xsl:template>

    <xsl:template name="declare-harness-step" as="node()+">
        <xsl:comment>substep to run a test suite whose XProc step functions are in scope</xsl:comment>
        <xsl:variable name="xproc3-uri" as="xs:anyURI" select="resolve-uri('src/xproc3/', $xspec-home)"/>
        <p:declare-step name="xproc-compile-run-format" type="x:xproc-compile-run-format">
            <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>

            <p:import href="{$xproc3-uri}harness-lib.xpl"/>
            <p:import href="{$xproc3-uri}run-xslt.xpl"/>

            <p:input port="source" primary="true" sequence="false" content-types="application/xml"/>
            <p:output port="result" serialization="map{{
                'indent':true(),
                'method':'xhtml',
                'encoding':'UTF-8',
                'include-content-type':true(),
                'omit-xml-declaration':false()
                }}" primary="true"/>

            <p:option name="xspec-home" as="xs:string?"/>
            <p:option name="force-focus" as="xs:string?" select="'{$force-focus}'"/>
            <p:option name="html-report-theme" as="xs:string" select="'{$html-report-theme}'"/>
            <!-- TODO: Declare inline-css option, when we can support it. -->
            <!-- TODO: Decide whether to support report-css-uri for t:format-report. -->

            <p:option name="parameters" as="map(xs:QName,item()*)" select="map{{}}"/>

            <xsl:comment>compile the suite into a stylesheet</xsl:comment>
            <x:compile-xproc name="compile" p:message="&#10;Creating Test Runner...">
                <p:with-option name="xspec-home" select="$xspec-home"/>
                <p:with-option name="force-focus" select="$force-focus"/>
                <p:with-option name="parameters" select="$parameters"/>
            </x:compile-xproc>

            <xsl:comment>run it</xsl:comment>
            <p:xslt name="run" template-name="x:main" message="&#10;Running Tests...">
                <p:with-input port="source">
                    <p:empty/>
                </p:with-input>
                <p:with-input port="stylesheet" pipe="@compile"/>
            </p:xslt>

            <xsl:comment>format the report</xsl:comment>
            <x:format-report p:message="&#10;Formatting Report...">
                <p:with-option name="xspec-home" select="$xspec-home"/>
                <p:with-option name="force-focus" select="$force-focus"/>
                <p:with-option name="html-report-theme" select="$html-report-theme"/>
                <p:with-option name="parameters" select="$parameters"/>
            </x:format-report>

        </p:declare-step>
    </xsl:template>

    <xsl:template name="execute-harness-step" as="node()+">
        <xsl:comment>run the test suite</xsl:comment>
        <x:xproc-compile-run-format xspec-home="{$xspec-home}"/>
    </xsl:template>
</xsl:stylesheet>
