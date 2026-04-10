<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:map="http://www.w3.org/2005/xpath-functions/map"
                xmlns:x="http://www.jenitennison.com/xslt/xspec"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                exclude-result-prefixes="#all"
                version="3.0">

   <!--
      Global params
   -->

   <!-- The special value '#none' is used to generate no "at" clause at all.
      By default, the URI is generated as a file relative to this stylesheet (because it comes with
      it in the XSpec release, but accessing the module on the file system is not always the best
      option, for instance for XML databases like eXist or MarkLogic). -->
   <xsl:param name="utils-library-at" as="xs:string?" />

   <!-- TODO: The at hint should not be always resolved (e.g. for MarkLogic). -->
   <xsl:param name="query-at" as="xs:string?"
      select="$initial-document/x:description/@query-at/resolve-uri(., base-uri())"/>

   <!--
      Serialization parameters applied to the compiled query
   -->
   <xsl:output omit-xml-declaration="yes" use-character-maps="x:disable-escaping" />

   <!--
      Main template of the XQuery-specific compiler
   -->
   <xsl:template name="x:main" as="node()+">
      <xsl:context-item as="element(x:description)" use="required" />

      <xsl:variable name="this" select="." as="element(x:description)" />

      <!-- Version declaration -->
      <xsl:text expand-text="yes">xquery version "{($this/@xquery-version, '3.1')[1]}";&#x0A;</xsl:text>

      <!-- Import module to be tested -->
      <xsl:text>&#x0A;</xsl:text>
      <xsl:text>(: the tested library module :)&#10;</xsl:text>
      <xsl:text expand-text="yes">import module "{$this/@query}"</xsl:text>
      <xsl:if test="exists($query-at)">
         <xsl:text expand-text="yes">&#x0A;at "{$query-at}"</xsl:text>
      </xsl:if>
      <xsl:text>;&#10;</xsl:text>

      <!-- Import helpers -->
      <xsl:if test="x:helper">
         <xsl:text>&#x0A;</xsl:text>
         <xsl:text>(: user-provided library module(s) :)&#x0A;</xsl:text>
         <xsl:call-template name="x:compile-helpers" />
      </xsl:if>

      <!-- Import utils -->
      <xsl:text>&#x0A;</xsl:text>
      <xsl:text>(: XSpec library modules providing tools :)&#x0A;</xsl:text>
      <xsl:variable name="utils-for-all-xquery-tests" as="map(xs:anyURI, xs:string)"
         select="
            map {
               $x:xspec-namespace: '../../common/common-utils.xqm',
               $x:deq-namespace:   '../../common/deep-equal.xqm',
               $x:rep-namespace:   '../../common/report-sequence.xqm'
            }" />
      <xsl:variable name="utils-for-xqs" as="map(xs:anyURI, xs:string)"
         select="
            map {
               $x:sn-namespace:    '../../schematron/select-node.xqm',
               $x:wrap-namespace:  '../../common/wrap.xqm'
            }" />
      <xsl:variable name="utils" as="map(xs:anyURI, xs:string)"
         select="(
            $utils-for-all-xquery-tests,
            $utils-for-xqs[exists($this/@schematron)][exists($this/@original-xspec)]
         ) => map:merge()" />
      <xsl:for-each select="map:keys($utils)">
         <xsl:sort />

         <xsl:text expand-text="yes">import module "{.}"</xsl:text>
         <xsl:if test="not($utils-library-at eq '#none')">
            <xsl:text expand-text="yes">&#x0A;at "{$utils(.) => resolve-uri()}"</xsl:text>
         </xsl:if>
         <xsl:text>;&#x0A;</xsl:text>
      </xsl:for-each>

      <xsl:text>&#x0A;</xsl:text>

      <!-- Declare namespaces. User-provided XPath expressions may use namespace prefixes.
         Unlike XSLT, XQuery requires them to be declared globally. -->
      <xsl:for-each select="x:copy-of-namespaces($initial-document/x:description)[name() (: Exclude the default namespace :)]">
         <xsl:text expand-text="yes">declare namespace {name()} = "{string()}";&#x0A;</xsl:text>
      </xsl:for-each>

      <!-- Serialization parameters for the test result report XML -->
      <xsl:text expand-text="yes">declare option {x:known-UQName('output:parameter-document')} "{resolve-uri('../../common/xml-report-serialization-parameters.xml')}";&#x0A;</xsl:text>

      <!-- Absolute URI of the master .xspec file -->
      <xsl:call-template name="x:declare-or-let-variable">
         <xsl:with-param name="as-global" select="true()" />
         <xsl:with-param name="uqname" select="x:known-UQName('x:xspec-uri')" />
         <xsl:with-param name="type" select="'xs:anyURI'" />
         <xsl:with-param name="value" as="text()">
            <xsl:text expand-text="yes">xs:anyURI("{$initial-document-actual-uri}")</xsl:text>
         </xsl:with-param>
      </xsl:call-template>

      <!-- Compile global variables. (Global params are not supported: xspec/xspec#1325) -->
      <xsl:variable name="global-vardecls" as="element(x:variable)*" select="x:variable" />
      <xsl:apply-templates select="$global-vardecls" mode="x:declare-variable" />

      <!-- Compile the top-level scenarios. -->
      <xsl:call-template name="x:compile-child-scenarios-or-expects" />
      <xsl:text>&#10;</xsl:text>

      <xsl:text>(: the query body of this main module, to run the suite :)&#10;</xsl:text>
      <xsl:text>(: set up the result document (the report) :)&#10;</xsl:text>
      <xsl:text>document {&#x0A;</xsl:text>

      <!-- <x:report> -->
      <xsl:text>element { </xsl:text>
      <xsl:value-of select="QName($x:xspec-namespace, 'report') => x:QName-expression()" />
      <xsl:text> } {&#x0A;</xsl:text>

      <xsl:call-template name="x:zero-or-more-node-constructors">
         <xsl:with-param name="nodes" as="attribute()+">
            <xsl:attribute name="xspec" select="$initial-document-actual-uri" />
            <xsl:choose>
               <xsl:when test="exists($this/@schematron) and exists($this/@original-xspec)">
                  <!-- If this file is derived from a test for Schematron, record @schematron.
                     That way, the HTML report indicates the schema, not the XQS module. -->
                  <xsl:attribute name="schematron" select="$this/@schematron" />                  
               </xsl:when>
               <xsl:otherwise>
                  <xsl:attribute name="query" select="$this/@query" />
                  <xsl:if test="exists($query-at)">
                     <xsl:attribute name="query-at" select="$query-at" />
                  </xsl:if>                  
               </xsl:otherwise>
            </xsl:choose>
         </xsl:with-param>
      </xsl:call-template>
      <xsl:text>,&#x0A;</xsl:text>

      <!-- @date must be evaluated at run time -->
      <xsl:text>attribute { QName('', 'date') } { current-dateTime() },&#x0A;</xsl:text>

      <xsl:if test="$measure-time">
         <xsl:call-template name="x:timestamp">
            <xsl:with-param name="event" select="'start'" />
         </xsl:call-template>
         <xsl:text>,&#x0A;</xsl:text>
      </xsl:if>

      <!-- Generate invocations of the compiled top-level scenarios. -->
      <xsl:text>(: invoke each compiled top-level x:scenario :)&#x0A;</xsl:text>
      <xsl:sequence>
         <xsl:call-template name="x:invoke-compiled-child-scenarios-or-expects">
            <xsl:with-param name="handled-child-vardecls" select="$global-vardecls" />
         </xsl:call-template>
         <xsl:on-empty>
            <xsl:text>()&#x0A;</xsl:text>
         </xsl:on-empty>
      </xsl:sequence>

      <xsl:if test="$measure-time">
         <xsl:text>,&#x0A;</xsl:text>
         <xsl:call-template name="x:timestamp">
            <xsl:with-param name="event" select="'end'" />
         </xsl:call-template>
      </xsl:if>

      <!-- </x:report> -->
      <xsl:text>}&#x0A;</xsl:text>

      <!-- End of the document constructor -->
      <xsl:text>}&#x0A;</xsl:text>
   </xsl:template>

   <!--
      Sub modules
   -->
   <xsl:include href="catch/try-catch.xsl" />
   <xsl:include href="compile/compile-expect.xsl" />
   <xsl:include href="compile/compile-helpers.xsl" />
   <xsl:include href="compile/compile-scenario.xsl" />
   <xsl:include href="declare-variable/declare-variable.xsl" />
   <xsl:include href="initial-check/perform-initial-check.xsl" />
   <xsl:include href="invoke-compiled/invoke-compiled-current-scenario-or-expect.xsl" />
   <xsl:include href="measure-time/timestamp.xsl" />
   <xsl:include href="node-constructor/node-constructor.xsl" />
   <xsl:include href="report/report-utils.xsl" />
   <xsl:include href="serialize/disable-escaping.xsl" />

</xsl:stylesheet>