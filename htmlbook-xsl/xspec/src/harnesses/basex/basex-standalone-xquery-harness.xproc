<?xml version="1.0" encoding="UTF-8"?>
<!-- ===================================================================== -->
<!--  File:       basex-standalone-xquery-harness.xproc                    -->
<!--  Author:     Florent Georges                                          -->
<!--  Date:       2011-08-30                                               -->
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
            pkg:import-uri="http://www.jenitennison.com/xslt/xspec/basex/harness/standalone/xquery.xproc"
            name="basex-standalone-xquery-harness"
            type="t:basex-standalone-xquery-harness"
            version="1.0">

   <p:documentation>
      <p>This pipeline executes an XSpec test suite with BaseX standalone.</p>
      <p><b>Primary input:</b> A XSpec test suite document.</p>
      <p><b>Primary output:</b> A formatted HTML XSpec report.</p>
      <p>The dir where you unzipped the XSpec archive on your filesystem is passed
        in the option 'xspec-home'.  The compiled test suite (the XQuery file to be
        actually evaluated) is saved on the filesystem to be passed to BaseX.  The
        name of this file is passed in the option 'compiled-file' (it defaults to a
        file in /tmp).  The BaseX JAR file is passed through 'basex-jar'.</p>
   </p:documentation>

   <p:serialization port="result" indent="true"/>

   <p:import href="../harness-lib.xpl"/>

   <t:parameters name="params"/>

   <p:group>
      <p:variable name="xspec-home" select="
          /c:param-set/c:param[@name eq 'xspec-home']/@value">
         <p:pipe step="params" port="parameters"/>
      </p:variable>
      <p:variable name="basex-jar" select="
          /c:param-set/c:param[@name eq 'basex-jar']/@value">
         <p:pipe step="params" port="parameters"/>
      </p:variable>
      <!-- TODO: Use a robust way to get a tmp file name from the OS... -->
      <p:variable name="compiled-file" select="
          ( /c:param-set/c:param[@name eq 'compiled-file']/@value,
            'file:/tmp/xspec-basex-compiled-suite.xq' )[1]">
         <p:pipe step="params" port="parameters"/>
      </p:variable>
      <p:variable name="utils-library-at" select="
          /c:param-set/c:param[@name eq 'utils-library-at']/@value">
         <p:pipe step="params" port="parameters"/>
      </p:variable>
      <!-- either no at location hint, or resolved from xspec-home if packaging not supported -->
      <p:variable name="utils-lib" select="
          if ( $utils-library-at ) then
            $utils-library-at
          else if ( $xspec-home ) then
            resolve-uri('src/compiler/generate-query-utils.xql', $xspec-home)
          else
            ''"/>

      <!-- compile the suite into a query -->
      <t:compile-xquery>
         <p:with-param  name="utils-library-at" select="$utils-lib"/>
      </t:compile-xquery>

      <!-- escape the query as text -->
      <p:escape-markup name="escape"/>

      <!-- store it on disk in order to pass it to BaseX -->
      <p:store method="text" name="store">
         <p:with-option name="href" select="$compiled-file"/>
      </p:store>

      <!-- run it on BaseX -->
      <p:choose cx:depends-on="store">
         <p:when test="p:value-available('basex-jar')">
            <!-- use Java directly, rely on 'basex-jar' -->
            <p:exec command="java">
               <p:with-option name="args" select="
                   string-join(
                     ('-cp', $basex-jar, 'org.basex.BaseX', $compiled-file),
                     ' ')"/>
               <p:input port="source">
                  <p:empty/>
               </p:input>
            </p:exec>
         </p:when>
         <p:otherwise>
            <!-- rely on a script 'basex' being in the PATH -->
            <p:exec command="basex">
               <p:with-option name="args" select="$compiled-file"/>
               <p:input port="source">
                  <p:empty/>
               </p:input>
            </p:exec>
         </p:otherwise>
      </p:choose>

      <!-- unwrap the exec step wrapper element -->
      <p:unwrap match="/c:result"/>

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
