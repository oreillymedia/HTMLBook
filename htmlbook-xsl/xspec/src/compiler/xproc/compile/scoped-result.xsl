<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.w3.org/1999/XSL/TransformAlias"
    xmlns:wrap="urn:x-xspec:common:wrap"
    xmlns:x="http://www.jenitennison.com/xslt/xspec" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" exclude-result-prefixes="#all" version="3.0">

    <xsl:template match="x:expect" mode="scope-result-variable">
        <xsl:param name="reason-for-pending" as="xs:string?" required="yes"/>
        <xsl:variable name="scoped-port" select="@port"/>
        <xsl:if test="@port and empty($reason-for-pending)">
            <if test="empty(${x:known-UQName('x:result')}?ports)">
                <!-- No data from output ports, probably due to caught error. Raising an error
                    here preempts an error from calling map:keys() below on an empty sequence. -->
                <message terminate="yes">
                    <xsl:call-template name="x:prefix-diag-message">
                        <xsl:with-param
                            name="message">No results to select using @port attribute.</xsl:with-param>
                    </xsl:call-template>
                </message>                
            </if>
            <if test="not('{$scoped-port}' = map:keys(${x:known-UQName('x:result')}?ports))"
                xmlns:map="http://www.w3.org/2005/xpath-functions/map">
                <message terminate="yes">
                    <xsl:call-template name="x:prefix-diag-message">
                        <xsl:with-param name="message"
                            expand-text="yes">No result for output port '{@port}'.</xsl:with-param>
                    </xsl:call-template>
                </message>
            </if>
            <!-- Within this x:expect element, scope $x:result to specified output port. -->
            <variable name="{x:known-UQName('x:document-properties')}" as="map(*)*"
                select="${x:known-UQName('x:result')}?ports?{$scoped-port}?document-properties"/>
            <variable name="{x:known-UQName('x:result')}" as="item()*"
                select="${x:known-UQName('x:result')}?ports?{$scoped-port}?document"/>
        </xsl:if>
    </xsl:template>

    <!-- Flags for deq:deep-equal() enclosed in ''. -->
    <xsl:function name="x:deep-equal-flags" as="xs:string">
        <xsl:param name="expect-element" as="element(x:expect)"/>
        <xsl:param name="xslt-version" as="xs:decimal"/>
        <xsl:sequence select="
                $x:apos ||
                '1'[$xslt-version eq 1] ||
                'd'[exists($expect-element/@port)] ||
                $x:apos"/>
    </xsl:function>

    <xsl:template name="define-impl-test-items" as="element(xsl:variable)">
        <variable name="{x:known-UQName('impl:test-items')}" as="item()*">
            <!-- Don't wrap $x:result. If a port produces multiple document nodes, wrapping them
                would merge their contents, which would interfere with verifying the documents. -->
            <sequence select="${x:known-UQName('x:result')}" />
        </variable>
    </xsl:template>
</xsl:stylesheet>
