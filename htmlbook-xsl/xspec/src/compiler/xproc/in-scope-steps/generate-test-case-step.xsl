<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:local="urn:x-xspec:compiler:xproc:in-scope-steps:generate-test-case-step:local"
    xmlns:p="http://www.w3.org/ns/xproc"
    xmlns:x="http://www.jenitennison.com/xslt/xspec" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" exclude-result-prefixes="#all" version="3.0">

    <xsl:include href="resolve-xproc-attribute.xsl"/>

    <xsl:variable name="xproc-version" as="xs:string" select="'3.1'"/>

    <xsl:template name="test-case-step-based-on-x-call" as="element(p:declare-step)">
        <xsl:context-item as="element(x:call)" use="required"/>
        <xsl:param name="parent-scenario" as="element(x:scenario)" select="parent::x:scenario"/>
        <xsl:variable name="call" as="element(x:call)" select="."/>
        <p:declare-step version="{$xproc-version}">

            <!-- Import the pipeline referenced in x:description/@xproc -->
            <xsl:variable name="resolved-xproc-attribute" as="xs:anyURI">
                <xsl:apply-templates select="$initial-document/x:description/@xproc"
                    mode="resolve-xproc-attribute"/>
            </xsl:variable>
            <p:import href="{$resolved-xproc-attribute}"/>

            <!-- Import a step needed when catching errors -->
            <xsl:if test="x:yes-no-synonym($parent-scenario/ancestor-or-self::*[@catch][1]/@catch, false())">
                <p:import href="{resolve-uri('error-code-attr-to-qname.xpl')}"/>
            </xsl:if>

            <!-- Map to return to step runner and XSLT test runner -->
            <p:output port="map-of-outputs"/>

            <!-- Data to pass from XSLT test runner to test target -->
            <p:option name="map-of-inputs"/>
            <p:option name="map-of-options"/>

            <xsl:variable name="instruction-to-enter-sut" as="element()+">
                <xsl:call-template name="call-test-target-process-results">
                    <xsl:with-param name="parent-scenario" select="$parent-scenario"/>
                </xsl:call-template>
            </xsl:variable>
            <xsl:for-each select="$parent-scenario">
                <!-- xsl:for-each is to change context -->
                <xsl:call-template name="x:enter-sut">
                    <xsl:with-param name="instruction" select="$instruction-to-enter-sut"/>
                </xsl:call-template>
            </xsl:for-each>
        </p:declare-step>
    </xsl:template>

    <xsl:template name="call-test-target-process-results" as="element()+">
        <xsl:context-item as="element(x:call)" use="required"/>
        <xsl:param name="parent-scenario" as="element(x:scenario)" required="yes"/>

        <xsl:variable name="call" as="element(x:call)" select="."/>

        <!-- Call the test target -->
        <xsl:variable name="step-QName" as="xs:QName"
            select="x:resolve-EQName-ignoring-default-ns($call/@step, $call)"/>
        <xsl:element name="{$step-QName}" namespace="{namespace-uri-from-QName($step-QName)}">
            <xsl:attribute name="name">test-target</xsl:attribute>
            <xsl:iterate select="$call/x:input">
                <xsl:choose>
                    <xsl:when test="exists(p:document) and (
                        exists(*[not(self::p:document)] | @href | @select | @as |
                        text()[normalize-space(.) ne ''])
                        )">
                        <xsl:message terminate="yes">
                            <xsl:call-template name="x:prefix-diag-message">
                                <xsl:with-param name="message" expand-text="yes">
                                    <xsl:text>p:document cannot combine with other </xsl:text>
                                    <xsl:text>elements, @href, @select, @as, or </xsl:text>
                                    <xsl:text>significant text nodes.</xsl:text>
                                </xsl:with-param>
                            </xsl:call-template>
                        </xsl:message>
                    </xsl:when>
                    <xsl:when test="exists(p:document)">
                        <!-- Pass x:input/p:document, except @xml:base, for evaluation
                                in XProc. -->
                        <p:with-input port="{@port}">
                            <xsl:sequence select="local:create-p-document(p:document)"/>
                        </p:with-input>
                    </xsl:when>
                    <xsl:otherwise>
                        <!-- Documents are prepared in XSLT. Retrieve them from map. -->
                        <p:with-input port="{@port}" select="$map-of-inputs?{@port}">
                            <p:inline/>
                        </p:with-input>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:iterate>
            <xsl:iterate select="$call/x:option">
                <xsl:variable name="option-UQName" as="xs:string"
                    select="x:UQName-from-EQName-ignoring-default-ns(@name, .)"/>
                <xsl:variable name="option-name-escaped" as="xs:string"
                    select="local:escape-curly-braces($option-UQName)"/>
                <xsl:choose>
                    <xsl:when test="exists(p:document) and (
                        exists(*[not(self::p:document)] | @href | @select | @as |
                        text()[normalize-space(.) ne ''])
                        )">
                        <xsl:message terminate="yes">
                            <xsl:call-template name="x:prefix-diag-message">
                                <xsl:with-param name="message" expand-text="yes">
                                    <xsl:text>p:document cannot combine with other </xsl:text>
                                    <xsl:text>elements, @href, @select, @as, or </xsl:text>
                                    <xsl:text>significant text nodes.</xsl:text>
                                </xsl:with-param>
                            </xsl:call-template>
                        </xsl:message>
                    </xsl:when>
                    <xsl:when test="count(p:document) gt 1">
                        <xsl:message terminate="yes">
                            <xsl:call-template name="x:prefix-diag-message">
                                <xsl:with-param name="message" expand-text="yes">
                                    <xsl:text>At most one p:document supported.</xsl:text>
                                </xsl:with-param>
                            </xsl:call-template>
                        </xsl:message>
                    </xsl:when>
                    <xsl:when test="exists(p:document)">
                        <!-- Pass x:option/p:document, except @xml:base, for evaluation
                                in XProc. -->
                        <p:with-option name="{$option-name-escaped}" select=".">
                            <xsl:if test="count(p:document) eq 1">
                                <!-- <p:with-option name="..." select="."> would raise error
                                        about missing context if the only child is excluded due
                                        to p:document/@use-when. So, copy that attribute to
                                        p:with-option. TODO: Revisit if supporting multiple
                                        x:option/p:document elements in the future. -->
                                <xsl:sequence select="p:document/@use-when"/>
                            </xsl:if>
                            <xsl:sequence select="local:create-p-document(p:document)"/>
                        </p:with-option>
                    </xsl:when>
                    <xsl:otherwise>
                        <!-- Documents are prepared in XSLT. Retrieve them from map. -->
                        <p:with-option name="{$option-name-escaped}">
                            <xsl:attribute name="select" expand-text="yes">$map-of-options('{$option-name-escaped}')</xsl:attribute>
                        </p:with-option>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:iterate>
        </xsl:element>

        <!-- Get names of output ports of test target -->
        <xsl:variable name="output-port-names" as="xs:string*"
            select="x:step-declaration($call, $parent-scenario)/p:output/@port"/>

        <!-- Create map with documents and their properties, organized by port -->
        <xsl:for-each select="$output-port-names">
            <xsl:variable name="this-port-name" as="xs:string" select="."/>
            <p:count limit="1" name="COUNT_{.}">
                <p:with-input pipe="{$this-port-name}@test-target"/>
            </p:count>
            <p:choose name="map_{$this-port-name}">
                <p:when test="number(.) eq 0">
                    <p:identity>
                        <p:with-input select="
                                map{{{{
                                    '{$this-port-name}': map{{{{
                                        'document': (),
                                        'document-properties': map{{{{ }}}}
                                    }}}}
                                }}}}">
                            <p:inline>
                                <any-context/>
                            </p:inline>
                        </p:with-input>
                    </p:identity>
                </p:when>
                <p:otherwise>
                    <p:identity>
                        <p:with-input select="
                                map{{{{
                                    '{$this-port-name}': map{{{{
                                        'document': .,
                                        'document-properties': p:document-properties(.)
                                    }}}}
                                }}}}" pipe="{.}@test-target"/>
                    </p:identity>
                </p:otherwise>
            </p:choose>
        </xsl:for-each>

        <!-- Merge all the maps, using duplicates="combine" to create sequences where a port
                has multiple documents -->
        <p:json-merge duplicates="combine" name="merged">
            <p:with-input port="source">
                <xsl:for-each select="$output-port-names">
                    <p:pipe step="map_{.}"/>
                </xsl:for-each>
                <xsl:on-empty>
                    <p:empty/>
                </xsl:on-empty>
            </p:with-input>
        </p:json-merge>
        <!-- Create the map with 'ports' at the top -->
        <p:identity name="ports-map">
            <p:with-input select="map{{{{'ports': .}}}}"/>
        </p:identity>
    </xsl:template>

    <!-- Create <p:document> element to insert in test-case step.
        Argument can be any of the following:
        - One or more x:input/p:document elements
        - One or more x:option/p:document elements
    -->
    <xsl:function name="local:create-p-document" as="element(p:document)+">
        <xsl:param name="p-document" as="element(p:document)+"/>
        <xsl:for-each select="$p-document">
            <xsl:variable name="new-xml-base" as="xs:anyURI" select="
                if (exists(@xml:base))
                then
                resolve-uri(@xml:base, $initial-document-actual-uri)
                else
                $initial-document-actual-uri"
            />
            <xsl:copy copy-namespaces="yes">
                <xsl:attribute name="xml:base" select="$new-xml-base"/>
                <xsl:apply-templates select="@* except (@xml:base, @port, @name, @as)"
                    mode="in-p-document"/>
                <xsl:apply-templates mode="in-p-document"/>
            </xsl:copy>
        </xsl:for-each>
    </xsl:function>

    <!-- Double curly braces -->
    <xsl:function name="local:escape-curly-braces" as="xs:string">
        <xsl:param name="s" as="xs:string"/>
        <xsl:sequence select="replace($s, '([\{\}])', '$1$1')"/>
    </xsl:function>

    <!-- Attributes need to have curly braces doubled when creating <p:document>
        in XSLT variable. -->
    <xsl:mode name="in-p-document" on-no-match="shallow-copy"/>
    <xsl:template match="attribute()" mode="in-p-document" as="attribute()">
        <xsl:attribute name="{name(.)}" namespace="{namespace-uri(.)}"
            select="local:escape-curly-braces(.)"/>
    </xsl:template>
    <xsl:template match="p:document/text()" mode="in-p-document" as="empty-sequence()"/>
</xsl:stylesheet>
