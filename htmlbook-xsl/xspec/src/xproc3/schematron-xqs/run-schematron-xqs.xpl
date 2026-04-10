<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step xmlns:p="http://www.w3.org/ns/xproc"
            xmlns:c="http://www.w3.org/ns/xproc-step"
            xmlns:x="http://www.jenitennison.com/xslt/xspec"
            xmlns:xs="http://www.w3.org/2001/XMLSchema"
            xmlns:map="http://www.w3.org/2005/xpath-functions/map"
            name="run-schematron-xqs"
            type="x:run-schematron-xqs"
            exclude-inline-prefixes="map xs x c p"
            version="3.1">

   <p:documentation>
      <p>This pipeline executes an XSpec test suite for Schematron with BaseX using the XQS implementation of Schematron.</p>
      <p>NOTE: This pipeline depends on the BaseX extension to XML Calabash 3 (v3.0.14 or later).</p>
      <p><b>Primary input:</b> An XSpec test suite document.</p>
      <p><b>Primary output:</b> A formatted HTML XSpec report.</p>
      <p>'xspec-home' option: The directory where you unzipped the XSpec archive on your filesystem.</p>
      <p>'xqs-home' option: Directory of XQS archive on your filesystem. Default: lib/XQS/ under xspec-home.</p>
      <p>'force-focus' option: The value `#none` (case sensitive) removes focus from all the scenarios.</p>
      <p>'html-report-theme' option: Color palette for HTML report, such as `blackwhite` (black on white),
         `whiteblack` (white on black), or `classic` (earlier green/pink design). Defaults to `blackwhite`.</p>
   </p:documentation>

   <p:import href="preprocess-schematron-xqs.xpl"/>
   <p:import href="../run-xquery.xpl"/>

   <p:input port="source" primary="true" sequence="false" content-types="application/xml"/>
   <p:output port="result"
      serialization="map{
         'indent':true(),
         'method':'xhtml',
         'encoding':'UTF-8',
         'include-content-type':true(),
         'omit-xml-declaration':false()
      }"
      primary="true"/>

   <p:option name="xspec-home" as="xs:string?"/>
   <p:option name="xqs-home" as="xs:string?"/>
   <p:option name="force-focus" as="xs:string?"/>
   <p:option name="html-report-theme" as="xs:string" select="'default'"/>
   <!-- TODO: Declare inline-css option, when we can support it. -->
   <!-- TODO: Decide whether to support measure-time for t:compile-xquery. -->
   <!-- TODO: Decide whether to support report-css-uri for t:format-report. -->
   
   <p:option name="parameters" as="map(xs:QName,item()*)" select="map{}"/>

   <!-- preprocess -->
   <x:preprocess-schematron-xqs p:message="Converting Schematron XSpec into XQuery XSpec...">
      <p:with-option name="xspec-home" select="$xspec-home"/>
      <p:with-option name="xqs-home" select="$xqs-home"/>
      <p:with-option name="parameters" select="$parameters"/>
   </x:preprocess-schematron-xqs>

   <!-- run generated test and produce report -->
   <x:run-xquery>
      <p:with-option name="xspec-home" select="$xspec-home"/>
      <p:with-option name="force-focus" select="$force-focus"/>
      <p:with-option name="html-report-theme" select="$html-report-theme"/>
      <p:with-option name="parameters" select="$parameters"/>
   </x:run-xquery>

</p:declare-step>
