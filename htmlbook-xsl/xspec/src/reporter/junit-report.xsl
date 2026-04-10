<?xml version="1.0" encoding="UTF-8"?>
<!-- =====================================================================

  Description:  XSLT to convert XSpec XML report to JUnit report
  Authors:      Kal Ahmed, github.com/kal
                Sandro Cirulli, github.com/cirulls
  License:      MIT License (https://opensource.org/licenses/MIT)

  ======================================================================== -->
<xsl:stylesheet version="3.0"
                xmlns:x="http://www.jenitennison.com/xslt/xspec"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                exclude-result-prefixes="#all">

    <xsl:include href="../common/parse-report.xsl" />

    <xsl:output indent="yes"/>

    <xsl:mode on-multiple-match="fail" on-no-match="fail" />

    <xsl:template match="document-node(element(x:report))" as="element(testsuites)">
        <xsl:apply-templates select="x:report" />
    </xsl:template>

    <xsl:template match="x:report" as="element(testsuites)">
        <testsuites name="{@xspec}">
            <xsl:apply-templates select="x:scenario"/>
        </testsuites>
    </xsl:template>

    <xsl:template match="x:scenario" as="element(testsuite)">
        <testsuite name="{x:label}"
                   tests="{x:descendant-tests(.) => count()}"
                   failures="{x:descendant-failed-tests(.) => count()}">
            <xsl:apply-templates select="x:test, x:scenario" />
        </testsuite>
    </xsl:template>

    <xsl:template match="x:scenario[ancestor::x:scenario]" as="element(testcase)*">
        <xsl:param name="prefix" as="xs:string?" />

        <xsl:apply-templates select="x:test, x:scenario">
            <xsl:with-param name="prefix" select="$prefix || x:label || ' '" />
        </xsl:apply-templates>
    </xsl:template>

    <xsl:template match="x:test" as="element(testcase)">
        <xsl:param name="prefix" as="xs:string?" />

        <xsl:variable name="status" as="xs:string">
            <xsl:choose>
                <xsl:when test="x:is-pending-test(.)">skipped</xsl:when>
                <xsl:when test="x:is-passed-test(.)">passed</xsl:when>
                <xsl:otherwise>failed</xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <testcase name="{$prefix || x:label}"
                  status="{$status}">
            <xsl:choose>
                <xsl:when test="x:is-pending-test(.)">
                    <skipped>
                        <xsl:value-of select="@pending" />
                    </skipped>
                </xsl:when>
                <xsl:when test="x:is-failed-test(.)">
                    <failure message="expect assertion failed">
                        <xsl:choose>
                            <xsl:when test="x:is-boolean-test(.)">
                                <!-- The word "Expecting" is based on https://github.com/xspec/xspec/blob/177b06c9c9970209047bef7fd5168453d545ab2d/src/reporter/format-xspec-report.xsl#L353 -->
                                <xsl:text expand-text="yes">Expecting: {x:test-attr(.)}</xsl:text>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:apply-templates select="x:expect"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </failure>
                </xsl:when>
            </xsl:choose>
        </testcase>
    </xsl:template>

    <xsl:template match="x:expect[@select][empty(attribute() except @select)][node() => empty()]"
        as="text()">
        <!-- The phrase "Expected Result" is based on https://github.com/xspec/xspec/blob/177b06c9c9970209047bef7fd5168453d545ab2d/src/reporter/format-xspec-report.xsl#L354 -->
        <xsl:text expand-text="yes">Expected Result: {@select}</xsl:text>
    </xsl:template>

    <xsl:template match="x:expect" as="empty-sequence()">
        <!-- Not simple -->
    </xsl:template>

</xsl:stylesheet>
