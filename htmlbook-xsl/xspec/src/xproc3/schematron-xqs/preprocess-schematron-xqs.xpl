<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step xmlns:p="http://www.w3.org/ns/xproc"
            xmlns:c="http://www.w3.org/ns/xproc-step"
            xmlns:x="http://www.jenitennison.com/xslt/xspec"
            xmlns:xs="http://www.w3.org/2001/XMLSchema"
            xmlns:map="http://www.w3.org/2005/xpath-functions/map"
            name="preprocess-schematron-xqs"
            type="x:preprocess-schematron-xqs"
            exclude-inline-prefixes="map xs x c p"
            version="3.1">

   <p:documentation>
      <p>This pipeline transforms an XSpec test suite for Schematron into an XSpec test suite for XQuery that validates using XQS.</p>
      <p><b>Primary input:</b> An XSpec test suite document for testing Schematron schema whose query binding is XQuery.</p>
      <p><b>Primary output:</b> An XSpec test suite document for testing validation using XQS.</p>
      <p>'xspec-home' option: The directory where you unzipped the XSpec archive on your filesystem.</p>
      <p>'xqs-home' option: Directory of XQS archive on your filesystem, accessed when the output test suite executes.
         Default: lib/XQS/ under xspec-home.</p>
   </p:documentation>

   <p:import href="../harness-lib.xpl"/>

   <p:input port="source" primary="true" sequence="false" content-types="application/xml"/>
   <p:output port="result" content-types="application/xml"
      serialization="map{
         'indent':true(),
         'method':'xml',
         'encoding':'UTF-8',
         'include-content-type':true(),
         'omit-xml-declaration':false()
      }"
      primary="true"/>

   <p:option name="xspec-home" as="xs:string?"/>
   <p:option name="xqs-home" as="xs:string?"/>
   <p:option name="parameters" as="map(xs:QName,item()*)" select="map{}"/>

   <p:variable name="preprocessor"
      select="if ( $xspec-home != '') then
      resolve-uri('src/schematron/schut-to-xspec.xsl', $xspec-home)
      else
      resolve-uri('../../schematron/schut-to-xspec.xsl')"/>

   <p:if test="empty(/x:description/@schematron)">
      <p:error code="x:ERR002">
         <p:with-input port="source">
            <p:inline>
               <message>Source document must be an XSpec test suite with @schematron attribute</message>
            </p:inline>
         </p:with-input>
      </p:error>
   </p:if>

   <!-- load the preprocessor -->
   <p:load name="preprocessor">
      <p:with-option name="href" select="$preprocessor"/>
   </p:load>

   <!-- from this test suite for Schematron, generate a test suite for XQuery -->
   <p:xslt>
      <p:with-input port="source" pipe="source@preprocess-schematron-xqs"/>
      <p:with-input port="stylesheet" pipe="@preprocessor"/>
      <p:with-option name="parameters" select="map{
         xs:QName('stylesheet-uri'): 'irrelevant for XQS but make it nonempty',
         xs:QName('xqs-home'): ($xqs-home, '../../lib/XQS/')[1]
         }"/>
      <p:with-option name="static-parameters"
         select="map{xs:QName('sch-impl-name'): 'xqs'}"/>
   </p:xslt>

   <!-- log the result? -->
   <x:log if-set="log-generated-xspec">
      <p:with-option name="parameters" select="$parameters"/>
   </x:log>

</p:declare-step>
