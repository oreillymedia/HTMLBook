<?xml version="1.0" encoding="UTF-8"?>
<!-- ===================================================================== -->
<!--  File:       generate-query-tests.xsl                                 -->
<!--  Author:     Jeni Tennsion                                            -->
<!--  URI:        http://xspec.googlecode.com/                             -->
<!--  Tags:                                                                -->
<!--    Copyright (c) 2008, 2010 Jeni Tennsion (see end of file.)          -->
<!-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -->


<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:test="http://www.jenitennison.com/xslt/unit-test"
                xmlns:x="http://www.jenitennison.com/xslt/xspec"
                xmlns:pkg="http://expath.org/ns/pkg"
                exclude-result-prefixes="xs test x"
                version="2.0">

   <xsl:import href="generate-common-tests.xsl"/>
   <xsl:import href="generate-query-helper.xsl"/>

   <pkg:import-uri>http://www.jenitennison.com/xslt/xspec/generate-query-tests.xsl</pkg:import-uri>

   <xsl:output omit-xml-declaration="yes"/>

   <!--
       The URI to use in the "at" clause of the import statement (aka
       the "location hint") for the library generate-query-utils.xql.
       The special value '#none' is used to generate no "at" clause at
       all.

       By defaut, the URI is generated as a file relative to this
       stylesheet (because it comes with it in the XSpec release, but
       accessing the module on the file system is not always the best
       option, for instance for XML databases like eXist or
       MarkLogic).
   -->
   <xsl:param name="utils-library-at" select="
       resolve-uri('generate-query-utils.xql', static-base-uri())"/>

   <xsl:variable name="xspec-prefix" as="xs:string">
      <xsl:variable name="e" select="/*"/>
      <xsl:variable name="u" select="xs:anyURI('http://www.jenitennison.com/xslt/xspec')"/>
      <xsl:sequence select="
          in-scope-prefixes($e)[namespace-uri-for-prefix(., $e) eq $u][1]"/>
   </xsl:variable>

   <!-- TODO: The at hint should not be always resolved (e.g. for MarkLogic). -->
   <xsl:param name="query-at" as="xs:string?" select="
       /x:description/@query-at/resolve-uri(., base-uri(..))"/>
   <!--xsl:param name="query-at" as="xs:string?" select="
       /x:description/@query-at"/-->

   <xsl:template match="/">
      <xsl:call-template name="x:generate-tests"/>
   </xsl:template>

   <xsl:template match="x:description" mode="x:decl-ns">
      <xsl:param name="except" as="xs:string"/>
      <xsl:variable name="e" as="element()" select="."/>
      <xsl:for-each select="in-scope-prefixes($e)[not(. = ('xml', $except))]">
         <xsl:text>declare namespace </xsl:text>
         <xsl:value-of select="."/>
         <xsl:text> = "</xsl:text>
         <xsl:value-of select="namespace-uri-for-prefix(., $e)"/>
         <xsl:text>";&#10;</xsl:text>
      </xsl:for-each>
   </xsl:template>

   <!-- *** x:generate-tests *** -->
   <!-- Does the generation of the test stylesheet -->
  
   <xsl:template match="x:description" mode="x:generate-tests">
      <xsl:variable name="this" select="."/>
      <!-- A prefix has to be defined for the target namespace on x:description. -->
      <!-- TODO: If not, we should generate one. -->
      <xsl:variable name="prefix" select="
          in-scope-prefixes($this)[
            namespace-uri-for-prefix(., $this) eq xs:anyURI($this/@query)
          ][1]"/>
      <xsl:text>import module namespace </xsl:text>
      <xsl:value-of select="$prefix"/>
      <xsl:text> = "</xsl:text>
      <xsl:value-of select="@query"/>
      <xsl:if test="exists($query-at)">
         <xsl:text>"&#10;  at "</xsl:text>
         <xsl:value-of select="$query-at"/>
      </xsl:if>
      <xsl:text>";&#10;</xsl:text>
      <!-- prevent double import in case we are testing this file in the compiled suite... -->
      <xsl:if test="@query ne 'http://www.jenitennison.com/xslt/unit-test'">
         <xsl:text>import module namespace test = </xsl:text>
         <xsl:text>"http://www.jenitennison.com/xslt/unit-test"</xsl:text>
         <xsl:if test="not($utils-library-at eq '#none')">
            <xsl:text>&#10;  at "</xsl:text>
            <xsl:value-of select="$utils-library-at"/>
            <xsl:text>"</xsl:text>
         </xsl:if>
         <xsl:text>;&#10;</xsl:text>
      </xsl:if>
      <xsl:apply-templates select="." mode="x:decl-ns">
         <xsl:with-param name="except" select="$prefix"/>
      </xsl:apply-templates>
      <!-- Compile the test suite params (aka global params). -->
      <xsl:call-template name="x:compile-params"/>
      <!-- Compile the top-level scenarios. -->
      <xsl:call-template name="x:compile-scenarios"/>
      <xsl:text>&#10;</xsl:text>
      <xsl:element name="{ $xspec-prefix }:report"
                   namespace="http://www.jenitennison.com/xslt/xspec">
         <xsl:attribute name="date"  select="current-dateTime()"/>
         <xsl:attribute name="query" select="$this/@query"/>
         <xsl:if test="exists($query-at)">
            <xsl:attribute name="query-at" select="$query-at"/>
         </xsl:if>
         <xsl:text> {&#10;</xsl:text>
         <!-- Generate calls to the compiled top-level scenarios. -->
         <xsl:call-template name="x:call-scenarios"/>
         <xsl:text>&#10;}&#10;</xsl:text>
      </xsl:element>
   </xsl:template>

   <!-- *** x:output-call *** -->
   <!-- Generates a call to the function compiled from a scenario or an expect element. --> 

   <xsl:template name="x:output-call">
      <xsl:param name="name"   as="xs:string"/>
      <xsl:param name="last"   as="xs:boolean"/>
      <xsl:param name="params" as="element(param)*"/>
      <xsl:if test="exists(preceding-sibling::x:*[1][self::x:pending])">
         <xsl:text>,&#10;</xsl:text>
      </xsl:if>
      <xsl:text>      let $</xsl:text>
      <xsl:value-of select="$xspec-prefix"/>
      <xsl:text>:tmp := local:</xsl:text>
      <xsl:value-of select="$name"/>
      <xsl:text>(</xsl:text>
      <xsl:for-each select="$params">
         <xsl:value-of select="@select"/>
         <xsl:if test="position() ne last()">
            <xsl:text>, </xsl:text>
         </xsl:if>
      </xsl:for-each>
      <xsl:text>) return (&#10;</xsl:text>
      <xsl:text>        $</xsl:text>
      <xsl:value-of select="$xspec-prefix"/>
      <xsl:text>:tmp</xsl:text>
      <xsl:if test="not($last)">
         <xsl:text>,</xsl:text>
      </xsl:if>
      <xsl:text>&#10;</xsl:text>
      <!-- Continue compiling calls. -->
      <xsl:call-template name="x:continue-call-scenarios"/>
      <xsl:text>      )&#10;</xsl:text>
   </xsl:template>

   <!-- *** x:compile *** -->
   <!-- Generates the functions that perform the tests -->
   <!--
       TODO: Add the $params parameter as in the x:output-scenario for XSLT.
   -->

   <xsl:template name="x:output-scenario">
      <xsl:param name="pending" select="()" tunnel="yes" as="node()?"/>
      <xsl:param name="context" select="()" tunnel="yes" as="element(x:context)?"/>
      <xsl:param name="call"    select="()" tunnel="yes" as="element(x:call)?"/>
      <xsl:param name="variables" as="element(x:variable)*"/>
      <xsl:param name="params"    as="element(param)*"/>
      <xsl:variable name="pending-p" select="exists($pending) and empty(ancestor-or-self::*/@focus)"/>
      <!-- x:context and x:call/@template not supported for XQuery -->
      <xsl:if test="exists($context)">
         <xsl:variable name="msg" select="
             concat('x:context not supported for XQuery (scenario ', x:label(.), ')')"/>
         <xsl:sequence select="error(xs:QName('x:XSPEC003'), $msg)"/>
      </xsl:if>
      <xsl:if test="exists($call/@template)">
         <xsl:variable name="msg" select="
             concat('x:call/@template not supported for XQuery (scenario ', x:label(.), ')')"/>
         <xsl:sequence select="error(xs:QName('x:XSPEC004'), $msg)"/>
      </xsl:if>
      <!-- x:call required if there are x:expect -->
      <xsl:if test="x:expect and not($call)">
         <xsl:variable name="msg" select="
             concat('there are x:expect but no x:call in scenario ''', x:label(.), '''')"/>
         <xsl:sequence select="error(xs:QName('x:XSPEC005'), $msg)"/>
      </xsl:if>
      <!--
        declare function local:...(...)
        {
      -->
      <xsl:text>&#10;declare function local:</xsl:text>
      <xsl:value-of select="generate-id()"/>
      <xsl:text>(</xsl:text>
      <xsl:value-of select="$params/concat('$', @name)" separator=", "/>
      <xsl:text>)&#10;{&#10;</xsl:text>
      <x:scenario>
         <xsl:if test="$pending-p">
            <xsl:attribute name="pending" select="$pending"/>
         </xsl:if>
         <x:label>
            <xsl:value-of select="x:label(.)"/>
         </x:label>
         <!-- Generate a seq ctor to generate x:context or x:call in the report. -->
         <xsl:apply-templates select="x:context|x:call" mode="x:report"/>
         <xsl:text>      &#10;{&#10;</xsl:text>
         <xsl:choose>
            <xsl:when test="not($pending-p)">
               <xsl:for-each select="$variables">
                  <xsl:apply-templates select="." mode="test:generate-variable-declarations">
                     <xsl:with-param name="var" select="@name"/>
                  </xsl:apply-templates>
               </xsl:for-each>
               <!--
                 let $xxx-param1 := ...
                 let $xxx-param2 := ...
                 let $t:result   := ...($xxx-param1, $xxx-param2)
                   return (
                     test:report-value($t:result, 'x:result'),
               -->
               <xsl:apply-templates select="$call/x:param[1]" mode="x:compile"/>
               <xsl:text>  let $</xsl:text>
               <xsl:value-of select="$xspec-prefix"/>
               <xsl:text>:result := </xsl:text>
               <xsl:value-of select="$call/@function"/>
               <xsl:text>(</xsl:text>
               <xsl:for-each select="$call/x:param">
                  <xsl:sort select="xs:integer(@position)"/>
                  <xsl:text>$</xsl:text>
                  <xsl:value-of select="( @name, generate-id() )[1]"/>
                  <xsl:if test="position() != last()">, </xsl:if>
               </xsl:for-each>
               <xsl:text>)&#10;</xsl:text>
               <xsl:text>    return (&#10;</xsl:text>
               <xsl:text>      test:report-value($</xsl:text>
               <xsl:value-of select="$xspec-prefix"/>
               <xsl:text>:result, '</xsl:text>
               <xsl:value-of select="$xspec-prefix"/>
               <xsl:text>:result'),&#10;</xsl:text>
            </xsl:when>
            <xsl:otherwise>
               <!--
                 let $t:result := ()
                   return (
               -->
               <xsl:text>  let $</xsl:text>
               <xsl:value-of select="$xspec-prefix"/>
               <xsl:text>:result := ()&#10;</xsl:text>
               <xsl:text>    return (&#10;</xsl:text>
            </xsl:otherwise>
         </xsl:choose>
         <xsl:call-template name="x:call-scenarios"/>
         <xsl:text>    )&#10;</xsl:text>
         <xsl:text>}&#10;</xsl:text>
      </x:scenario>
      <xsl:text>&#10;};&#10;</xsl:text>
      <xsl:call-template name="x:compile-scenarios"/>
   </xsl:template>

   <!--
       Generate an XQuery function from the expect element.
       
       This function, when called, checks the expectation against the
       actual result of the test and return the corresponding t:test
       element for the XML report.
   -->
   <xsl:template name="x:output-expect">
      <xsl:param name="pending" select="()"    tunnel="yes" as="node()?"/>
      <xsl:param name="call"    required="yes" tunnel="yes" as="element(x:call)?"/>
      <xsl:param name="params"  required="yes"              as="element(param)*"/>
      <xsl:variable name="pending-p" select="exists($pending) and empty(ancestor::*/@focus)"/>
      <!--
        declare function local:...($t:result as item()*)
        {
      -->
      <xsl:text>&#10;declare function local:</xsl:text>
      <xsl:value-of select="generate-id()"/>
      <xsl:text>(</xsl:text>
      <xsl:for-each select="$params">
         <xsl:text>$</xsl:text>
         <xsl:value-of select="@name"/>
         <xsl:if test="position() ne last()">
            <xsl:text>, </xsl:text>
         </xsl:if>
      </xsl:for-each>
      <xsl:text>)&#10;{&#10;</xsl:text>
      <xsl:if test="not($pending-p)">
         <!--
           let $local:expected :=
               ( ... )
         -->
         <xsl:text>  let $local:expected    := (: expected result :)&#10;</xsl:text>
         <!-- FIXME: Not correct, the x:expect model is more complex than
              a simple variable... (see how the original stylesheet, for
              XSLT, handles that...) Factorize with the XSLT version...
              The value of $local:expected depends on x:expect's depends
              on content, @href and @select. -->
         <xsl:text>      ( </xsl:text>
         <xsl:value-of select="@select"/>
         <xsl:copy-of select="node()"/>
         <xsl:text> )&#10;</xsl:text>
         <!--
           let $local:test-result :=
               if ( $t:result instance of node()+ ) then
                 document { $t:result }/( ... )
               else
                 ( ... )
         -->
         <!--xsl:text>  let $local:test-result := (: evaluate the predicate :)&#10;</xsl:text>
         <xsl:text>      if ( $</xsl:text>
         <xsl:value-of select="$xspec-prefix"/>
         <xsl:text>:result instance of node()+ ) then&#10;</xsl:text>
         <xsl:text>        document { $</xsl:text>
         <xsl:value-of select="$xspec-prefix"/>
         <xsl:text>:result }/( </xsl:text>
         <xsl:value-of select="@test"/>
         <xsl:text> )&#10;</xsl:text>
         <xsl:text>      else&#10;</xsl:text>
         <xsl:text>        ( </xsl:text>
         <xsl:value-of select="@test"/>
         <xsl:text> )&#10;</xsl:text>
         <!- -
           let $local:successful :=
               if ( $local:test-result instance of xs:boolean ) then
                 $local:test-result
               else
                 test:deep-equal($local:expected, $local:test-result)
         - ->
         <xsl:text>  let $local:successful  := (: did the test pass?:)&#10;</xsl:text>
         <xsl:text>      if ( $local:test-result instance of xs:boolean ) then&#10;</xsl:text>
         <xsl:text>        $local:test-result&#10;</xsl:text>
         <xsl:text>      else&#10;</xsl:text>
         <xsl:text>        test:deep-equal($local:expected, $local:test-result)&#10;</xsl:text-->
         <!--
           IF @test ==>
           let $local:successful :=
               ( ...)
           
           ELSE ==>
           let $local:successful :=
               test:deep-equal($local:expected, $x:result)
         -->
         <xsl:text>  let $local:successful as xs:boolean := (: did the test pass?:)&#10;</xsl:text>
         <xsl:choose>
            <xsl:when test="exists(@test) and exists(node())">
               <xsl:text>      test:deep-equal($local:expected, </xsl:text>
               <xsl:value-of select="@test"/>
               <xsl:text>)&#10;</xsl:text>
            </xsl:when>
            <xsl:when test="exists(@test)">
               <xsl:text>      ( </xsl:text>
               <xsl:value-of select="@test"/>
               <xsl:text> )&#10;</xsl:text>
            </xsl:when>
            <xsl:otherwise>
               <xsl:text>      test:deep-equal($local:expected, $</xsl:text>
               <xsl:value-of select="$xspec-prefix"/>
               <xsl:text>:result)&#10;</xsl:text>
            </xsl:otherwise>
         </xsl:choose>
         <xsl:text>    return&#10;      </xsl:text>
      </xsl:if>
      <!--
        return the x:test element for the report
      -->
      <x:test>
         <xsl:choose>
            <xsl:when test="$pending-p">
               <xsl:attribute name="pending" select="$pending"/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:attribute name="successful" select="'{ $local:successful }'"/>
            </xsl:otherwise>
         </xsl:choose>
         <xsl:sequence select="x:label(.)"/>
         <xsl:if test="not($pending-p)">
            <!--xsl:if test="@test">
               <xsl:text>&#10;      { if ( $local:test-result instance of xs:boolean ) then () else test:report-value($local:test-result, '</xsl:text>
               <xsl:value-of select="$xspec-prefix"/>
               <xsl:text>:result') }</xsl:text>
            </xsl:if-->
            <xsl:text>&#10;      { test:report-value($local:expected, '</xsl:text>
            <xsl:value-of select="$xspec-prefix"/>
            <xsl:text>:expect') }</xsl:text>
         </xsl:if>
      </x:test>
      <xsl:text>&#10;};&#10;</xsl:text>
   </xsl:template>

   <!-- *** x:generate-declarations *** -->
   <!-- Code to generate parameter declarations -->
   <!--
       TODO: For x:param, define external variable (which can have a
       default value in XQuery 1.1, but not in 1.0, so we will need to
       generate an error for global x:param with default value...)
   -->
   <xsl:template match="x:param|x:variable" mode="x:generate-declarations">
      <xsl:apply-templates select="." mode="test:generate-variable-declarations">
         <xsl:with-param name="var"    select="@name" />
         <xsl:with-param name="global" select="true()"/>
      </xsl:apply-templates>
   </xsl:template>

   <xsl:template match="x:space" mode="test:create-xslt-generator">
      <text>
         <xsl:value-of select="."/>
      </text>
   </xsl:template>  

   <xsl:template match="x:param" mode="x:report">
      <xsl:element name="x:{local-name()}">
         <xsl:apply-templates select="@*" mode="x:report"/>
         <xsl:apply-templates mode="test:create-xslt-generator"/>
      </xsl:element>
   </xsl:template>

   <xsl:template match="x:call" mode="x:report">
      <x:call>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="x:report"/>
      </x:call>
   </xsl:template>

   <xsl:template match="@select" mode="x:report">
      <xsl:attribute name="select" select="
          replace(replace(., '\{', '{{'), '\}', '}}')"/>
   </xsl:template>

   <xsl:template match="@*" mode="x:report">
      <xsl:sequence select="."/>
   </xsl:template>

   <xsl:function name="x:label" as="node()?">
      <xsl:param name="labelled" as="element()"/>
      <xsl:choose>
         <xsl:when test="exists($labelled/x:label)">
            <xsl:sequence select="$labelled/x:label"/>
         </xsl:when>
         <xsl:otherwise>
            <x:label><xsl:value-of select="$labelled/@label"/></x:label>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>

</xsl:stylesheet>


<!-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -->
<!-- DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS COMMENT.             -->
<!--                                                                       -->
<!-- Copyright (c) 2008, 2010 Jeni Tennsion                                -->
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
