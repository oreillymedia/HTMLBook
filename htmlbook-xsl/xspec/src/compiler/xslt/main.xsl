<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.w3.org/1999/XSL/TransformAlias"
                xmlns:x="http://www.jenitennison.com/xslt/xspec"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                exclude-result-prefixes="#all"
                version="3.0">

   <!--
      Namespace alias for literal result elements
   -->
   <xsl:namespace-alias stylesheet-prefix="#default" result-prefix="xsl" />

   <!--
      Serialization parameters applied to the compiled stylesheet
   -->
   <xsl:output indent="yes" />

   <!--
      Main template of the XSLT-specific compiler
   -->
   <xsl:template name="x:main" as="element(xsl:stylesheet)">
      <xsl:context-item as="element(x:description)" use="required" />

      <!-- True if this XSpec is testing Schematron -->
      <xsl:variable name="is-schematron" as="xs:boolean" select="exists(@original-xspec)" />

      <!-- True if this XSpec is testing XProc. Assume a test suite doesn't have @xproc
         along with either @original-xspec or @stylesheet, because XProc step scenarios
         use x:call[@step], whereas XSLT and Schematron scenarios don't. -->
      <xsl:variable name="is-xproc" as="xs:boolean" select="exists(@xproc)" />

      <!-- The compiled stylesheet element. -->
      <xsl:element name="xsl:stylesheet" namespace="{$x:xsl-namespace}">
         <xsl:attribute name="exclude-result-prefixes" select="'#all'" />
         <xsl:attribute name="version" select="x:xslt-version(.) => x:decimal-string()" />

         <!-- Indent the following comment -->
         <xsl:text>&#10;   </xsl:text>

         <xsl:if test="not($is-external) and not($is-xproc)">
            <xsl:comment> the tested stylesheet </xsl:comment>
            <xsl:element name="xsl:import" namespace="{$x:xsl-namespace}">
               <xsl:attribute name="href" select="@stylesheet" />
            </xsl:element>
         </xsl:if>

         <xsl:if test="x:helper">
            <xsl:comment> user-provided library module(s) </xsl:comment>
            <xsl:call-template name="x:compile-helpers" />
         </xsl:if>

         <xsl:comment> XSpec library modules providing tools </xsl:comment>
         <xsl:for-each
            select="
               '../../common/runtime-utils.xsl',
               '../../schematron/select-node.xsl'[$is-schematron]">
            <xsl:element name="xsl:include" namespace="{$x:xsl-namespace}">
               <xsl:attribute name="href" select="resolve-uri(.)" />
            </xsl:element>
         </xsl:for-each>

         <xsl:if test="$is-external">
            <xsl:element name="xsl:global-context-item" namespace="{$x:xsl-namespace}">
               <xsl:attribute name="use" select="'absent'" />
            </xsl:element>
         </xsl:if>

         <!-- Absolute URI of .xsl file to be tested -->
         <xsl:if test="not($is-xproc)">
            <variable name="{x:known-UQName('x:stylesheet-uri')}" as="{x:known-UQName('xs:anyURI')}">
               <xsl:value-of select="@stylesheet" />
            </variable>
         </xsl:if>

         <!-- Absolute URI of the master .xspec file (Original one if specified i.e. Schematron) -->
         <xsl:variable name="xspec-master-uri" as="xs:anyURI"
            select="(@original-xspec, $initial-document-actual-uri)[1] cast as xs:anyURI" />
         <variable name="{x:known-UQName('x:xspec-uri')}" as="{x:known-UQName('xs:anyURI')}">
            <xsl:value-of select="$xspec-master-uri" />
         </variable>

         <!-- Let the compiled stylesheet know whether external or not -->
         <variable name="{x:known-UQName('x:is-external')}" as="{x:known-UQName('xs:boolean')}"
            select="{$is-external}()" />

         <!-- $impl:thread-aware must be evaluated at run time static analysis -->
         <variable name="{x:known-UQName('impl:thread-aware')}" as="{x:known-UQName('xs:boolean')}"
            select="(system-property('{x:known-UQName('xsl:product-name')}') eq 'SAXON') and starts-with(system-property('{x:known-UQName('xsl:product-version')}'), 'EE ')"
            static="yes" />

         <!-- $impl:logical-processor-count must be evaluated at run time -->
         <variable name="{x:known-UQName('impl:logical-processor-count')}"
            as="{x:known-UQName('xs:integer')}" use-when="${x:known-UQName('impl:thread-aware')}">
            <xsl:attribute name="select">
               <xsl:text>Q{java:java.lang.Runtime}getRuntime() => Q{java:java.lang.Runtime}availableProcessors()</xsl:text>
            </xsl:attribute>
         </variable>

         <!-- Default $impl:thread-count. This global variable will be used when x:description or
            x:scenario has @threads but the XSLT processor at run time is not capable of threads. -->
         <variable name="{x:known-UQName('impl:thread-count')}" as="{x:known-UQName('xs:integer')}"
            select="1" use-when="${x:known-UQName('impl:thread-aware')} => not()" />

         <!-- Compile global params and global variables. -->
         <xsl:variable name="global-vardecls" as="element()*" select="x:param | x:variable" />
         <xsl:apply-templates select="$global-vardecls" mode="x:declare-variable" />

         <xsl:if test="$is-external">
            <!-- If no $x:saxon-config is provided by global x:variable, declare a dummy one so that
               $x:saxon-config is always available -->
            <xsl:if
               test="
                  empty(
                     x:variable[x:resolve-EQName-ignoring-default-ns(@name, .) eq xs:QName('x:saxon-config')]
                  )">
               <variable name="{x:known-UQName('x:saxon-config')}" as="empty-sequence()" />
            </xsl:if>
         </xsl:if>

         <!-- The main compiled template. -->
         <xsl:comment> the main template to run the suite </xsl:comment>
         <xsl:element name="xsl:template" namespace="{$x:xsl-namespace}">
            <xsl:attribute name="name" select="x:known-UQName('x:main')" />
            <xsl:attribute name="as" select="'empty-sequence()'" />

            <xsl:element name="xsl:context-item" namespace="{$x:xsl-namespace}">
               <xsl:attribute name="use" select="'absent'" />
            </xsl:element>

            <xsl:text>&#10;      </xsl:text><xsl:comment> info message </xsl:comment>
            <message>
               <xsl:apply-templates select="." mode="info-message"/>   
            </message>

            <xsl:comment> set up the result document (the report) </xsl:comment>
            <!-- Use xsl:result-document/@format to avoid clashes with <xsl:output> in the stylesheet
               being tested which would otherwise govern the output of the report XML. -->
            <xsl:element name="xsl:result-document" namespace="{$x:xsl-namespace}">
               <!-- Escape curly braces because @format is AVT -->
               <xsl:attribute name="format"
                  select="'Q{{' || $x:xspec-namespace || '}}xml-report-serialization-parameters'" />
               <xsl:element name="xsl:element" namespace="{$x:xsl-namespace}">
                  <xsl:attribute name="name" select="'report'" />
                  <xsl:attribute name="namespace" select="$x:xspec-namespace" />

                  <xsl:variable name="attributes" as="attribute()+">
                     <xsl:attribute name="xspec" select="$xspec-master-uri" />

                     <!-- This @stylesheet is used by ../../reporter/coverage-report.xsl -->
                     <xsl:sequence select="@stylesheet" />

                     <!-- @xproc is used by ../../reporter/format-xspec-report.xsl -->
                     <xsl:sequence select="@xproc" />

                     <!-- Do not always copy @schematron.
                        @schematron may exist even when this running instance of XSpec is not
                        testing Schematron. -->
                     <xsl:if test="$is-schematron">
                        <xsl:sequence select="@schematron" />
                     </xsl:if>
                  </xsl:variable>
                  <xsl:apply-templates select="$attributes" mode="x:node-constructor" />

                  <!-- @date must be evaluated at run time -->
                  <xsl:element name="xsl:attribute" namespace="{$x:xsl-namespace}">
                     <xsl:attribute name="name" select="'date'" />
                     <xsl:attribute name="namespace" />
                     <xsl:attribute name="select" select="'current-dateTime()'" />
                  </xsl:element>

                  <xsl:call-template name="x:timestamp">
                     <xsl:with-param name="event" select="'start'" />
                  </xsl:call-template>

                  <!-- Generate invocations of the compiled top-level scenarios. -->
                  <xsl:text>&#10;            </xsl:text><xsl:comment> invoke each compiled top-level x:scenario </xsl:comment>
                  <xsl:call-template name="x:invoke-compiled-child-scenarios-or-expects">
                     <xsl:with-param name="handled-child-vardecls" select="$global-vardecls" />
                  </xsl:call-template>

                  <xsl:call-template name="x:timestamp">
                     <xsl:with-param name="event" select="'end'" />
                  </xsl:call-template>
               </xsl:element>
            </xsl:element>
         </xsl:element>

         <!-- Compile the top-level scenarios. -->
         <xsl:call-template name="x:compile-child-scenarios-or-expects" />
      </xsl:element>
   </xsl:template>

</xsl:stylesheet>