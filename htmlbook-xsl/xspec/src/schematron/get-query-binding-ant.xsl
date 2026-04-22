<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:sch="http://purl.oclc.org/dsdl/schematron"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    exclude-result-prefixes="#all" version="3.0">

    <!--
        Transform an XSpec test document as follows:
        * If x:description has no @schematron attribute, return a nonempty but irrelevant
          XML result.
        * Otherwise, parse the Schematron schema under test, and return an
          element tree that becomes these boolean-valued Ant properties:
            xspec.schematron.querylanguage.is.xquery
            xspec.schematron.querylanguage.is.xslt
    -->
    <xsl:template as="element(xspec)?" match="/">
        <xsl:variable name="schema-uri" as="xs:anyURI*"
            select="/*/@schematron ! resolve-uri(., base-uri(/*))"/>
        <xsl:choose>
            <xsl:when test="exists(/*/@schematron)">
                <xsl:variable name="queryLanguage" select="
                    doc(resolve-uri(/*/@schematron, base-uri(/*)))/sch:schema/@queryBinding
                    ! replace(., '[0-9]+', '')"/>
                <xspec>
                    <schematron>
                        <querylanguage>
                            <is>
                                <xquery>
                                    <!-- If $queryLanguage is empty sequence, the value is false, not empty -->
                                    <xsl:value-of select="$queryLanguage = 'xquery'"/>
                                </xquery>
                                <xslt>
                                    <xsl:value-of select="$queryLanguage = 'xslt'"/>
                                </xslt>
                            </is>
                        </querylanguage>
                    </schematron>
                </xspec>
            </xsl:when>
            <xsl:otherwise>
                <!-- If output document is empty, Ant raises an error, so return something unobtrusive. -->
                <xspec>
                    <dummy-property/>
                </xspec>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

</xsl:stylesheet>
