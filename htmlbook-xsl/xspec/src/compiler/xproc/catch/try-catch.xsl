<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.w3.org/ns/xproc" xmlns:p="http://www.w3.org/ns/xproc"
    xmlns:x="http://www.jenitennison.com/xslt/xspec"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" exclude-result-prefixes="#all" version="3.0">

    <xsl:template name="x:try-catch" as="element(p:try)">
        <xsl:context-item use="absent"/>

        <xsl:param name="instruction" as="element()+" required="yes"/>

        <try>
            <xsl:sequence select="$instruction"/>
            <catch name="catch">
                <identity name="caught-error-document">
                    <with-input pipe="error@catch"/>
                </identity>

                <!-- First, resolve c:error/@code attribute values as QNames. Then store in map. -->
                <error-code-attr-to-qname name="error-code-qnames" xmlns="urn:x-xspec:compile:impl"/>
                <identity name="code-entry-in-map">
                    <with-input select="map{{{{ 'code': . }}}}"/>
                </identity>

                <identity name="value-entry-in-map">
                    <with-input select="map{{{{ 'value': . }}}}" pipe="result@caught-error-document"
                    />
                </identity>

                <identity name="description-entry-in-map">
                    <with-input select="map{{{{ 'description': () }}}}"/>
                </identity>

                <identity name="module-entry-in-map">
                    <with-input select="map{{{{
                        'module': //Q{{{{http://www.w3.org/ns/xproc-step}}}}error/@href/string()
                        }}}}" pipe="result@caught-error-document"/>
                </identity>

                <identity name="line-number-entry-in-map">
                    <with-input select="map{{{{
                        'line-number': //Q{{{{http://www.w3.org/ns/xproc-step}}}}error/@line ! Q{{{{http://www.w3.org/2001/XMLSchema}}}}integer(.)
                        }}}}" pipe="result@caught-error-document"/>
                </identity>

                <identity name="column-number-entry-in-map">
                    <with-input select="map{{{{
                        'column-number': //Q{{{{http://www.w3.org/ns/xproc-step}}}}error/@column ! Q{{{{http://www.w3.org/2001/XMLSchema}}}}integer(.)
                        }}}}" pipe="result@caught-error-document"/>
                </identity>

                <json-merge duplicates="reject">
                    <with-input port="source">
                        <pipe step="code-entry-in-map"/>
                        <pipe step="description-entry-in-map"/>
                        <pipe step="value-entry-in-map"/>
                        <pipe step="module-entry-in-map"/>
                        <pipe step="line-number-entry-in-map"/>
                        <pipe step="column-number-entry-in-map"/>
                    </with-input>
                </json-merge>

                <!-- Create the map with 'err' at the top -->
                <identity name="err-map">
                    <with-input select="map{{{{'err': .}}}}"/>
                </identity>
            </catch>
        </try>
    </xsl:template>
</xsl:stylesheet>
