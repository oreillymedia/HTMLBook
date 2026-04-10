<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step xmlns:p="http://www.w3.org/ns/xproc"
    xmlns:x="http://www.jenitennison.com/xslt/xspec" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    name="run-xproc" type="x:run-xproc" version="3.1">

    <p:documentation>
        <p>This pipeline executes an XSpec test suite for XProc.</p>
        <p><b>Primary input:</b> An XSpec test suite document.</p>
        <p><b>Primary output:</b> A formatted HTML XSpec report.</p>
        <p>'xspec-home' option: The directory where you unzipped the XSpec archive on your filesystem.</p>
        <p>'force-focus' option: The value `#none` (case sensitive) removes focus from all the scenarios.</p>
        <p>'html-report-theme' option: Color palette for HTML report, such as `blackwhite` (black on white),
            `whiteblack` (white on black), or `classic` (earlier green/pink design). Defaults to `blackwhite`.</p>
    </p:documentation>

    <p:input port="source" primary="true" sequence="false"/>
    <p:output port="result"
        serialization="map{
        'indent':true(),
        'method':'xhtml',
        'encoding':'UTF-8',
        'include-content-type':true(),
        'omit-xml-declaration':false()
        }"
        primary="true"/>

    <p:option name="xspec-home" as="xs:string" select="resolve-uri('../../../')"/>
    <p:option name="force-focus" as="xs:string?"/>
    <p:option name="html-report-theme" as="xs:string" select="'default'"/>
    <!-- TODO: Declare inline-css option, when we can support it. -->
    <!-- TODO: Decide whether to support is-external or measure-time for t:compile-xslt. -->
    <!-- TODO: Decide whether to support report-css-uri for t:format-report. -->

    <!-- Generate the pipeline we want to run. -->
    <p:xslt name="generate-pipeline">
        <p:with-input port="stylesheet" href="generate-pipeline.xsl"/>
        <p:with-option name="parameters" select="map{
            'xspec-home': $xspec-home,
            'force-focus': $force-focus,
            'html-report-theme': $html-report-theme
            }"/>
        <p:with-option name="template-name" select="'generate-pipeline'"/>
    </p:xslt>

    <!-- Get the XSpec test suite back for use in the generated pipeline -->
    <p:identity name="mydocument">
        <p:with-input pipe="source@run-xproc"/>
    </p:identity>

    <!-- Call p:run with the generated pipeline, and it will
        connect the source document to the p:run-input source port -->
    <p:run>
        <p:with-input pipe="@generate-pipeline"/>
        <p:run-input port="xspec"/>
        <p:output port="result"/>
    </p:run>

</p:declare-step>
