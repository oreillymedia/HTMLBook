<?xml version="1.0" encoding="UTF-8"?>
<p:library xmlns:pf="http://www.jenitennison.com/xslt/xspec/xproc/steps/wrap-standard-functions"
    xmlns:p="http://www.w3.org/ns/xproc" xmlns:xs="http://www.w3.org/2001/XMLSchema" version="3.0">

    <!--
        This library provides wrappers around selected standard XProc functions
        so that an XPath expression in an XSpec test can use the functionality
        via step functions.
    -->

    <p:declare-step type="pf:system-property" name="system-property">
        <p:output port="result"/>
        <p:option name="property" required="true" as="xs:string"/>
        <p:identity>
            <p:with-input select="string()">
                <p:inline>{ p:system-property($property) }</p:inline>
            </p:with-input>
        </p:identity>
    </p:declare-step>
</p:library>
