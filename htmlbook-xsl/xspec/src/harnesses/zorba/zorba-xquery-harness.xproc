<?xml version="1.0" encoding="UTF-8"?>
<!-- ===================================================================== -->
<!--  File:       zorba-xquery-harness.xproc                               -->
<!--  Author:     Florent Georges                                          -->
<!--  Date:       2011-09-18                                               -->
<!--  URI:        http://xspec.googlecode.com/                             -->
<!--  Tags:                                                                -->
<!--    Copyright (c) 2011 Florent Georges (see end of file.)              -->
<!-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -->


<p:pipeline xmlns:p="http://www.w3.org/ns/xproc"
            xmlns:c="http://www.w3.org/ns/xproc-step"
            xmlns:cx="http://xmlcalabash.com/ns/extensions"
            xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
            xmlns:xs="http://www.w3.org/2001/XMLSchema"
            xmlns:t="http://www.jenitennison.com/xslt/xspec"
            xmlns:pkg="http://expath.org/ns/pkg"
            pkg:import-uri="http://www.jenitennison.com/xslt/xspec/zorba/harness/xquery.xproc"
            name="zorba-xquery-harness"
            type="t:zorba-xquery-harness"
            version="1.0">

   <p:documentation>
      <p>This pipeline executes an XSpec test suite with Zorba.</p>
      <p><b>Primary input:</b> A XSpec test suite document.</p>
      <p><b>Primary output:</b> A formatted HTML XSpec report.</p>
      <p>The dir where you unzipped the XSpec archive on your filesystem is passed
        in the option 'xspec-home'.  The compiled test suite (the XQuery file to be
        actually evaluated) is saved on the filesystem to be passed to Zorba.  The
        name of this file is passed in the option 'compiled-file' (it defaults to a
        file in /tmp).  It relies on a script called 'zorba' being available in the
        system's $PATH.</p>
   </p:documentation>

   <p:serialization port="result" indent="true"/>

   <p:import href="../harness-lib.xpl"/>

   <t:parameters name="params"/>

   <p:group>
      <p:variable name="xspec-home" select="/c:param-set/c:param[@name eq 'xspec-home']/@value">
         <p:pipe step="params" port="parameters"/>
      </p:variable>

      <!-- TODO: Use a robust way to get a tmp file name from the OS... -->
      <p:variable name="compiled-file" select="
          ( /c:param-set/c:param[@name eq 'compiled-file']/@value,
            'file:///tmp/xspec-zorba-compiled-suite.xq' )[1]">
         <p:pipe step="params" port="parameters"/>
      </p:variable>

      <p:variable name="at-param" select="/c:param-set/c:param[@name eq 'query-at']/@value">
         <p:pipe step="params" port="parameters"/>
      </p:variable>
      <p:variable name="at-attr" select="resolve-uri(/t:description/@query-at, base-uri(/))"/>
      <p:variable name="at-tmp" select="( $at-param, $at-attr )[.][1]"/>
      <!-- Saxon's resolve-uri() returns file:/ with only one slashes, which Zorba
           does not understand. -->
      <p:variable name="query-at" select="
          if ( starts-with($at-tmp, 'file:/') and not(starts-with($at-tmp, 'file:///')) ) then
            concat('file:///', substring($at-tmp, 7))
          else
            $at-tmp"/>

      <p:variable name="utils-tmp" select="
          ( /c:param-set/c:param[@name eq 'utils-library-at']/@value,
            resolve-uri('src/compiler/generate-query-utils.xql', $xspec-home) )[1]">
         <p:pipe step="params" port="parameters"/>
      </p:variable>
      <!-- Saxon's resolve-uri() returns file:/ with only one slashes, which Zorba
           does not understand. -->
      <p:variable name="utils-lib" select="
          if ( starts-with($utils-tmp, 'file:/') and not(starts-with($utils-tmp, 'file:///')) ) then
            concat('file:///', substring($utils-tmp, 7))
          else
            $utils-tmp"/>

      <!-- compile the suite into a query -->
      <t:compile-xquery>
         <p:with-param name="query-at"         select="$query-at"/>
         <p:with-param name="utils-library-at" select="$utils-lib"/>
      </t:compile-xquery>

      <!-- escape the query as text -->
      <p:escape-markup name="escape"/>

      <!-- store it on disk in order to pass it to zorba -->
      <p:store method="text" name="store">
         <p:with-option name="href" select="$compiled-file"/>
      </p:store>

      <!-- run it on zorba, rely on a script 'zorba' being in the PATH -->
      <p:exec command="zorba" name="run" cx:depends-on="store">
         <!-- Zorba does not accept a URI, only a file path, so we have to remove
              the 'file:' part.  TODO: Report it to the Zorba mailing list. -->
         <p:with-option name="args" select="
             concat('-f -q ', substring-after($compiled-file, ':'))"/>
         <p:input port="source">
            <p:empty/>
         </p:input>
      </p:exec>

      <!-- unwrap the p:exec step wrapper element -->
      <p:unwrap name="unwrap" match="/c:result">
         <p:input port="source">
            <p:pipe step="run" port="result"/>
         </p:input>
      </p:unwrap>

      <!-- format the report -->
      <t:format-report/>
   </p:group>

</p:pipeline>


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
