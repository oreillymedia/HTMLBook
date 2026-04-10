<?xml version="1.0" encoding="UTF-8"?>
<!-- ===================================================================== -->
<!--  File:       xquery-harness.xproc                               -->
<!--  Author:     Florent Georges                                          -->
<!--  Date:       2011-08-30                                               -->
<!--  Contributors:                                                        -->
<!--        George Bina - updated to use XProc 3                           -->
<!--  Date:       2025-06-09                                               -->
<!--  URI:        http://github.com/xspec/xspec                            -->
<!--  Tags:                                                                -->
<!--    Copyright (c) 2011 Florent Georges (see end of file.)              -->
<!-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -->


<p:declare-step xmlns:p="http://www.w3.org/ns/xproc"
            xmlns:c="http://www.w3.org/ns/xproc-step"
            xmlns:t="http://www.jenitennison.com/xslt/xspec"
            xmlns:pkg="http://expath.org/ns/pkg"
            xmlns:xs="http://www.w3.org/2001/XMLSchema"
            xmlns:map="http://www.w3.org/2005/xpath-functions/map"
            pkg:import-uri="http://www.jenitennison.com/xslt/xspec/saxon/harness/xquery.xproc"
            name="run-xquery"
            type="t:run-xquery"
            exclude-inline-prefixes="map xs pkg t c p"
            version="3.1">

   <p:documentation>
      <p>This pipeline executes an XSpec test suite for XQuery.</p>
      <p><b>Primary input:</b> An XSpec test suite document.</p>
      <p><b>Primary output:</b> A formatted HTML XSpec report.</p>
      <p>'xspec-home' option: The directory where you unzipped the XSpec archive on your filesystem.</p>
      <p>'force-focus' option: The value `#none` (case sensitive) removes focus from all the scenarios.</p>
      <p>'html-report-theme' option: Color palette for HTML report, such as `blackwhite` (black on white),
         `whiteblack` (white on black), or `classic` (earlier green/pink design). Defaults to `blackwhite`.</p>
   </p:documentation>

   <p:import href="harness-lib.xpl"/>

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

   <p:option name="xspec-home" as="xs:string?"/>
   <p:option name="force-focus" as="xs:string?"/>
   <p:option name="html-report-theme" as="xs:string" select="'default'"/>
   <!-- TODO: Declare inline-css option, when we can support it. -->
   <!-- TODO: Decide whether to support measure-time for t:compile-xquery. -->
   <!-- TODO: Decide whether to support report-css-uri for t:format-report. -->

   <p:option name="parameters" as="map(xs:QName,item()*)" select="map{}"/>


   <!-- compile the suite into a query -->
   <t:compile-xquery name="compile" p:message="Creating Test Runner...">
      <p:with-option name="xspec-home" select="$xspec-home"/>
      <p:with-option name="force-focus" select="$force-focus"/>
      <p:with-option name="parameters" select="$parameters"/>
   </t:compile-xquery>

   <!-- get the XQuery script as text -->
   <t:extract-xquery name="queryText"/>

   <!-- run it on Saxon bundled with XML Calabash 3 (default) or another
      XQuery processor, based on XProc processor configuration -->
   <p:xquery name="run" message="&#10;Running Tests...">
      <p:with-input port="source"><p:empty/></p:with-input>
      <p:with-input port="query" pipe="@queryText"/>
   </p:xquery>

   <!-- format the report -->
   <t:format-report p:message="&#10;Formatting Report...">
      <p:with-option name="xspec-home" select="$xspec-home"/>
      <p:with-option name="force-focus" select="$force-focus"/>
      <p:with-option name="html-report-theme" select="$html-report-theme"/>
      <p:with-option name="parameters" select="$parameters"/>
   </t:format-report>

</p:declare-step>


<!-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -->
<!-- DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS COMMENT.             -->
<!--                                                                       -->
<!-- Copyright (c) 2011 Florent Georges                                    -->
<!--                                                                       -->
<!-- The contents of this file are subject to the MIT License (see the URI -->
<!-- http://www.opensource.org/licenses/mit-license.php for details).      -->
<!--                                                                       -->
<!-- Permission is hereby granted, free of charge, to any person obtaining -->
<!-- a copy of this software and associated documentation files (the       -->
<!-- "Software"), to deal in the Software without restriction, including   -->
<!-- without limitation the rights to use, copy, modify, merge, publish,   -->
<!-- distribute, sublicense, and/or sell copies of the Software, and to    -->
<!-- permit persons to whom the Software is furnished to do so, subject to -->
<!-- the following conditions:                                             -->
<!--                                                                       -->
<!-- The above copyright notice and this permission notice shall be        -->
<!-- included in all copies or substantial portions of the Software.       -->
<!--                                                                       -->
<!-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,       -->
<!-- EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF    -->
<!-- MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.-->
<!-- IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY  -->
<!-- CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,  -->
<!-- TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE     -->
<!-- SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                -->
<!-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -->
