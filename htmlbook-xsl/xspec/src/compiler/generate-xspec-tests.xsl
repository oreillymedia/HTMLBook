<?xml version="1.0" encoding="UTF-8"?>
<!-- ===================================================================== -->
<!--  File:       generate-xspec-tests.xsl                                 -->
<!--  Author:     Jeni Tennsion                                            -->
<!--  URI:        http://xspec.googlecode.com/                             -->
<!--  Tags:                                                                -->
<!--    Copyright (c) 2008, 2010 Jeni Tennsion (see end of file.)          -->
<!-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -->


<xsl:stylesheet version="2.0" 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns="http://www.w3.org/1999/XSL/TransformAlias"
  xmlns:test="http://www.jenitennison.com/xslt/unit-test"
  exclude-result-prefixes="#default test"
  xmlns:x="http://www.jenitennison.com/xslt/xspec"
  xmlns:__x="http://www.w3.org/1999/XSL/TransformAliasAlias"
  xmlns:pkg="http://expath.org/ns/pkg"
  xmlns:impl="urn:x-xspec:compile:xslt:impl">

<xsl:import href="generate-common-tests.xsl"/>
<xsl:import href="generate-tests-helper.xsl" />

<pkg:import-uri>http://www.jenitennison.com/xslt/xspec/generate-xspec-tests.xsl</pkg:import-uri>

<xsl:namespace-alias stylesheet-prefix="#default" result-prefix="xsl"/>

<xsl:preserve-space elements="x:space" />

<xsl:output indent="yes" encoding="ISO-8859-1" />  


<xsl:variable name="xspec-ns" select="'http://www.jenitennison.com/xslt/xspec'"/>

<xsl:variable name="stylesheet-uri" as="xs:anyURI" 
  select="resolve-uri(/x:description/@stylesheet, base-uri(/x:description))" />  

<xsl:variable name="stylesheet" as="document-node()" 
  select="doc($stylesheet-uri)" />

<xsl:template match="/">
   <xsl:call-template name="x:generate-tests"/>
</xsl:template>

<!-- *** x:generate-tests *** -->
<!-- Does the generation of the test stylesheet -->
  
<xsl:template match="x:description" mode="x:generate-tests">
  <!-- The compiled stylesheet element. -->
  <stylesheet version="2.0">
    <xsl:apply-templates select="." mode="x:copy-namespaces" />
  	<import href="{$stylesheet-uri}" />
  	<import href="{resolve-uri('generate-tests-utils.xsl', static-base-uri())}"/>
    <!-- This namespace alias is used for when the testing process needs to test
         the generation of XSLT! -->
    <namespace-alias stylesheet-prefix="__x" result-prefix="xsl" />
    <variable name="x:stylesheet-uri" as="xs:string" select="'{$stylesheet-uri}'" />
  	<output name="x:report" method="xml" indent="yes" />
    <!-- Compile the test suite params (aka global params). -->
    <xsl:call-template name="x:compile-params"/>
    <!-- The main compiled template. -->
    <template name="x:main">
      <message>
        <text>Testing with </text>
        <value-of select="system-property('xsl:product-name')" />
        <text><xsl:text> </xsl:text></text>
        <value-of select="system-property('xsl:product-version')" />
      </message>
    	<result-document format="x:report">
	      <processing-instruction name="xml-stylesheet">
	        <xsl:text>type="text/xsl" href="</xsl:text>
	        <xsl:value-of select="resolve-uri('format-xspec-report.xsl',
	          static-base-uri())" />
	        <xsl:text>"</xsl:text>
	      </processing-instruction>
	      <!-- This bit of jiggery-pokery with the $stylesheet-uri variable is so
	        that the URI appears in the trace report generated from running the
	        test stylesheet, which can then be picked up by stylesheets that
	        process *that* to generate a coverage report -->
	      <x:report stylesheet="{{$x:stylesheet-uri}}" date="{{current-dateTime()}}">
                 <!-- Generate calls to the compiled top-level scenarios. -->
                 <xsl:call-template name="x:call-scenarios"/>
	      </x:report>
    	</result-document>
    </template>
    <!-- Compile the top-level scenarios. -->
    <xsl:call-template name="x:compile-scenarios"/>
  </stylesheet>
</xsl:template>

<!-- *** x:output-call *** -->
<!-- Generates a call to the template compiled from a scenario or an expect element. --> 

<xsl:template name="x:output-call">
   <xsl:param name="name"   as="xs:string"/>
   <xsl:param name="last"   as="xs:boolean"/>
   <xsl:param name="params" as="element(param)*"/>
   <call-template name="x:{ $name }">
      <xsl:for-each select="$params">
         <with-param name="{ @name }" select="{ @select }"/>
      </xsl:for-each>
   </call-template>
   <!-- Continue compiling calls. -->
   <xsl:call-template name="x:continue-call-scenarios"/>
</xsl:template>

<!-- *** x:compile *** -->
<!-- Generates the templates that perform the tests -->

<xsl:template name="x:output-scenario">
  <xsl:param name="pending"   select="()" tunnel="yes" as="node()?"/>
  <xsl:param name="apply"     select="()" tunnel="yes" as="element(x:apply)?"/>
  <xsl:param name="call"      select="()" tunnel="yes" as="element(x:call)?"/>
  <xsl:param name="context"   select="()" tunnel="yes" as="element(x:context)?"/>
  <xsl:param name="variables" as="element(x:variable)*"/>
  <xsl:param name="params"    as="element(param)*"/>
  <xsl:variable name="pending-p" select="exists($pending) and empty(ancestor-or-self::*/@focus)"/>
  <!-- We have to create these error messages at this stage because before now
       we didn't have merged versions of the environment -->
  <xsl:if test="$context/@href and ($context/node() except $context/x:param)">
    <xsl:message terminate="yes">
      <xsl:text>ERROR in scenario "</xsl:text>
      <xsl:value-of select="x:label(.)" />
      <xsl:text>": can't set the context document using both the href</xsl:text>
      <xsl:text> attribute and the content of &lt;context&gt;</xsl:text>
    </xsl:message>
  </xsl:if>
  <xsl:if test="$call/@template and $call/@function">
    <xsl:message terminate="yes">
      <xsl:text>ERROR in scenario "</xsl:text>
      <xsl:value-of select="x:label(.)" />
      <xsl:text>": can't call a function and a template at the same time</xsl:text>
    </xsl:message>
  </xsl:if>
  <xsl:if test="$apply and $context">
    <xsl:message terminate="yes">
      <xsl:text>ERROR in scenario "</xsl:text>
      <xsl:value-of select="x:label(.)" />
      <xsl:text>": can't use apply and set a context at the same time</xsl:text>
    </xsl:message>
  </xsl:if>
  <xsl:if test="$apply and $call">
    <xsl:message terminate="yes">
      <xsl:text>ERROR in scenario "</xsl:text>
      <xsl:value-of select="x:label(.)" />
      <xsl:text>": can't use apply and call at the same time</xsl:text>
    </xsl:message>
  </xsl:if>
  <xsl:if test="$context and $call/@function">
    <xsl:message terminate="yes">
      <xsl:text>ERROR in scenario "</xsl:text>
      <xsl:value-of select="x:label(.)" />
      <xsl:text>": can't set a context and call a function at the same time</xsl:text>
    </xsl:message>
  </xsl:if>
  <xsl:if test="x:expect and not($call) and not($apply) and not($context)">
    <xsl:message terminate="yes">
      <xsl:text>ERROR in scenario "</xsl:text>
      <xsl:value-of select="x:label(.)" />
      <xsl:text>": there are tests in this scenario but no call, or apply or context has been given</xsl:text>
    </xsl:message>
  </xsl:if>
  <template name="x:{generate-id()}">
     <xsl:for-each select="$params">
        <param name="{ @name }" required="yes"/>
     </xsl:for-each>
     <message>
        <xsl:if test="$pending-p">
           <xsl:text>PENDING: </xsl:text>
           <xsl:if test="$pending != ''">
              <xsl:text>(</xsl:text>
              <xsl:value-of select="normalize-space($pending)"/>
              <xsl:text>) </xsl:text>
           </xsl:if>
        </xsl:if>
        <xsl:if test="parent::x:scenario">
           <xsl:text>..</xsl:text>
        </xsl:if>
        <xsl:value-of select="normalize-space(x:label(.))"/>
     </message>
    <x:scenario>
      <xsl:if test="$pending-p">
        <xsl:attribute name="pending" select="$pending" />
      </xsl:if>
      <xsl:sequence select="x:label(.)" />
      <xsl:apply-templates select="x:apply | x:call | x:context" mode="x:report" />
      <xsl:apply-templates select="$variables" mode="x:generate-declarations"/>
      <xsl:if test="not($pending-p) and x:expect">
        <variable name="x:result" as="item()*">
          <xsl:choose>
            <xsl:when test="$call/@template">
              <!-- Set up variables containing the parameter values -->
              <xsl:apply-templates select="$call/x:param[1]" mode="x:compile" />
              <!-- Create the template call -->
              <xsl:variable name="template-call">
                <call-template name="{$call/@template}">
                  <xsl:for-each select="$call/x:param">
                    <with-param name="{@name}" select="${@name}">
                      <xsl:copy-of select="@tunnel, @as" />
                    </with-param>
                  </xsl:for-each>
                </call-template>
              </xsl:variable>
              <xsl:choose>
                <xsl:when test="$context">
                  <!-- Set up the $context variable -->
                  <xsl:apply-templates select="$context" mode="x:setup-context"/>
                  <!-- Switch to the context and call the template -->
                  <for-each select="$context">
                    <xsl:copy-of select="$template-call" />
                  </for-each>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:copy-of select="$template-call" />
                </xsl:otherwise>
              </xsl:choose>
            </xsl:when>
            <xsl:when test="$call/@function">
              <!-- Set up variables containing the parameter values -->
              <xsl:apply-templates select="$call/x:param[1]" mode="x:compile" />
              <!-- Create the function call -->
              <sequence>
                <xsl:attribute name="select">
                  <xsl:value-of select="$call/@function" />
                  <xsl:text>(</xsl:text>
                  <xsl:for-each select="$call/x:param">
                    <xsl:sort select="xs:integer(@position)" />
                    <xsl:text>$</xsl:text>
                    <xsl:value-of select="if (@name) then @name else generate-id()" />
                    <xsl:if test="position() != last()">, </xsl:if>
                  </xsl:for-each>
                  <xsl:text>)</xsl:text>
                </xsl:attribute>
              </sequence>
            </xsl:when>
            <xsl:when test="$apply">
               <!-- TODO: FIXME: ... -->
               <xsl:message terminate="yes">
                  <xsl:text>The instruction t:apply is not supported yet!</xsl:text>
               </xsl:message>
               <!-- Set up variables containing the parameter values -->
               <xsl:apply-templates select="$apply/x:param[1]" mode="x:compile"/>
               <!-- Create the apply templates instruction -->
               <apply-templates>
                  <xsl:copy-of select="$apply/@select | $apply/@mode"/>
                  <xsl:for-each select="$apply/x:param">
                     <with-param name="{ @name }" select="${ @name }">
                        <xsl:copy-of select="@tunnel"/>
                     </with-param>
                  </xsl:for-each>
               </apply-templates>
            </xsl:when>
            <xsl:when test="$context">
              <!-- Set up the $context variable -->
              <xsl:apply-templates select="$context" mode="x:setup-context"/>
              <!-- Set up variables containing the parameter values -->
              <xsl:apply-templates select="$context/x:param[1]" mode="x:compile"/>
              <!-- Create the template call -->
              <apply-templates select="$impl:context">
                <xsl:sequence select="$context/@mode" />
                <xsl:for-each select="$context/x:param">
                  <with-param name="{@name}" select="${@name}">
                    <xsl:copy-of select="@tunnel, @as" />
                  </with-param>
                </xsl:for-each>
              </apply-templates>
            </xsl:when>
            <xsl:otherwise>
               <!-- TODO: Adapt to a new error reporting facility (above usages too). -->
               <xsl:message terminate="yes">Error: cannot happen.</xsl:message>
            </xsl:otherwise>
          </xsl:choose>      
        </variable>
        <call-template name="test:report-value">
          <with-param name="value" select="$x:result" />
          <with-param name="wrapper-name" select="'x:result'" />
          <with-param name="wrapper-ns" select="'{ $xspec-ns }'"/>
        </call-template>
      </xsl:if>
      <xsl:call-template name="x:call-scenarios"/>
    </x:scenario>
  </template>
  <xsl:call-template name="x:compile-scenarios"/>
</xsl:template>

<!--
    Generate the following:
        
        TODO: Review if it is still ok, regarding the below new description...

        <template name="x:...">
           <param name="x:result" required="yes"/>       # if not pending
           <message>
              Running (pending?) assertion...
           </message>
           # if not pending
              <variable name="impl:expected" ...>   # depend on content, @href and @select
              # if @context, change the context to the result of evaluating it
              #   if no @context, the result is the context (if exactly one item)
              # if @assert, evaluate it, the result must be boolean
              # if @test, evaluate it with result as context node then
              #   if it is not a boolean, compare it to $impl:expected
              # if no @test, compare result to $impl:expected
           # fi
           <x:test>
              ...
           </x:test>
        </template>
    
    By assertion
    @assert
    @assert, @context

    By comparing nodes
    content
    content, @context

    By comparing atomic values
    @select
    @select, @context

    Old-school (result wrapped into doc node)
    @test             (= @assert)
    @test, @context   (= @assert, @context)
    content, @test    (= content, @context)
      -> actually, that's not exctly what has been implemented
         now we evaluate @test, and if it results to one boolean,
         then that's an assert, if not it is compared to content

    Context: if multiple items, loop as current item ($x:result still full result)
      - with @assert, assertion eval'd once for each
      - with content, compare the whole sequence
      - with @select, compare the whole sequence
    
    IF @context
      set context (@context)
    ELIF @test AND content
      set context (@test)
    ELSE
      set context ($result)
    
    IF @assert
      assert (@assert)
    ELIF content
      compare (content)
    ELIF @select
      compare (@select)
    ELIF @test AND content
      compare (content)
    ELIF @test
      assert (@test)
    
    set context (@context):
      variable with-context := true
      variable context
        if count($result) <= 1
          eval @context with $result as context
        else
          eval @context without any context
        -> must be ONE item
    
    set context (@test):
      variable with-context := true
      variable context
        like set context (@context), but if node()+, then wrap in doc node
    
    set context ($result):
      variable with-context := true
      variable context
        no context                  if count($result) ne 1
        like set context (@context) if no @test
        like set context (@test)    if @test

    no context:
      variable with-context := false
      variable context      := ()
    
    assert (@assert):
      if $with-context
        evaluate assert with $context
      else
        evaluate assert without context
    
    compare (content):
      if $with-context
        compare $context to content
      else
        compare $result to content
    
    compare (@select):
      if $with-context
        compare $context to content
      else
        compare $result to content
    
    assert (@test):
      if $with-context
        evaluate @test with $context
      else
        evaluate @test without context
-->
<xsl:template name="x:output-expect-FIXME-TOREMOVE">
  <xsl:param name="pending" select="()"    tunnel="yes" as="node()?"/>
  <xsl:param name="context" required="yes" tunnel="yes" as="element(x:context)?"/>
  <xsl:param name="call"    required="yes" tunnel="yes" as="element(x:call)?"/>
  <xsl:param name="params"  required="yes"              as="element(param)*"/>
  <xsl:variable name="pending-p" select="exists($pending) and empty(ancestor::*/@focus)"/>
  <template name="x:{generate-id()}">
     <xsl:for-each select="$params">
        <param name="{ @name }" required="{ @required }"/>
     </xsl:for-each>
    <message>
      <xsl:if test="$pending-p">
        <xsl:text>PENDING: </xsl:text>
        <xsl:if test="normalize-space($pending) != ''">(<xsl:value-of select="normalize-space($pending)"/>) </xsl:if>
      </xsl:if>
      <xsl:value-of select="normalize-space(x:label(.))"/>
    </message>
    <xsl:if test="not($pending-p)">
      <xsl:variable name="version" as="xs:double" 
        select="(ancestor-or-self::*[@xslt-version]/@xslt-version, 2.0)[1]" />
      <xsl:apply-templates select="." mode="test:generate-variable-declarations">
        <xsl:with-param name="var" select="'impl:expected'" />
      </xsl:apply-templates>
      <xsl:choose>
        <xsl:when test="@test">
          <!-- This variable declaration could be moved from here (the
               template generated from x:expect) to the template
               generated from x:scenario. It depends only on
               $x:result, so could be computed only once. -->
          <variable name="impl:test-items" as="item()*">
            <choose>
              <!-- From trying this out, it seems like it's useful for the test
                   to be able to test the nodes that are generated in the
                   $x:result as if they were *children* of the context node.
                   Have to experiment a bit to see if that really is the case.                   
                   TODO: To remove. Use directly $x:result instead.  See issue 14. -->
              <when test="$x:result instance of node()+">
                <document>
                  <copy-of select="$x:result" />
                </document>
              </when>
              <otherwise>
                <sequence select="$x:result" />
              </otherwise>
            </choose>
          </variable>
          <variable name="impl:test-result" as="item()*">
             <choose>
                <when test="count($impl:test-items) eq 1">
                   <for-each select="$impl:test-items">
                      <sequence select="{ @test }" version="{ $version }"/>
                   </for-each>
                </when>
                <otherwise>
                   <sequence select="{ @test }" version="{ $version }"/>
                </otherwise>
             </choose>
          </variable>
          <!-- TODO: A predicate should always return exactly one boolean, or
               this is an error.  See issue 5.-->
          <variable name="impl:boolean-test" as="xs:boolean"
            select="$impl:test-result instance of xs:boolean" />
          <variable name="impl:successful" as="xs:boolean"
            select="if ($impl:boolean-test) then $impl:test-result
                    else test:deep-equal($impl:expected, $impl:test-result, {$version})" />
        </xsl:when>
        <xsl:otherwise>
          <variable name="impl:successful" as="xs:boolean" 
            select="test:deep-equal($impl:expected, $x:result, {$version})" />
        </xsl:otherwise>
      </xsl:choose>
      <if test="not($impl:successful)">
        <message>
          <xsl:text>      FAILED</xsl:text>
        </message>
      </if>
    </xsl:if>
    <x:test>
      <xsl:choose>
        <xsl:when test="$pending-p">
          <xsl:attribute name="pending" select="$pending" />
        </xsl:when>
        <xsl:otherwise>
          <xsl:attribute name="successful" select="'{$impl:successful}'" />
        </xsl:otherwise>
      </xsl:choose>
      <xsl:sequence select="x:label(.)"/>
      <xsl:if test="not($pending-p)">
         <xsl:if test="@test">
            <if test="not($impl:boolean-test)">
               <call-template name="test:report-value">
                  <with-param name="value"        select="$impl:test-result"/>
                  <with-param name="wrapper-name" select="'x:result'"/>
                  <with-param name="wrapper-ns"   select="'{ $xspec-ns }'"/>
               </call-template>
            </if>
         </xsl:if>
         <call-template name="test:report-value">
            <with-param name="value"        select="$impl:expected"/>
            <with-param name="wrapper-name" select="'x:expect'"/>
            <with-param name="wrapper-ns"   select="'{ $xspec-ns }'"/>
         </call-template>
      </xsl:if>
    </x:test>
 </template>
</xsl:template>

 <xsl:template name="x:output-expect">
   <xsl:param name="pending" select="()"    tunnel="yes" as="node()?"/>
   <xsl:param name="context" required="yes" tunnel="yes" as="element(x:context)?"/>
   <xsl:param name="call"    required="yes" tunnel="yes" as="element(x:call)?"/>
   <xsl:param name="params"  required="yes"              as="element(param)*"/>
   <xsl:variable name="pending-p" select="exists($pending) and empty(ancestor::*/@focus)"/>
   <template name="x:{generate-id()}">
      <xsl:for-each select="$params">
         <param name="{ @name }" required="{ @required }"/>
      </xsl:for-each>
      <message>
         <xsl:if test="$pending-p">
            <xsl:text>PENDING: </xsl:text>
            <xsl:if test="normalize-space($pending) != ''">
               <xsl:text>(</xsl:text>
               <xsl:value-of select="normalize-space($pending)"/>
               <xsl:text>) </xsl:text>
            </xsl:if>
         </xsl:if>
         <xsl:value-of select="normalize-space(x:label(.))"/>
      </message>
      <xsl:variable name="is-assert" select="empty(node()|@select)"/>
      <xsl:if test="not($pending-p)">
         <xsl:variable name="version" as="xs:double" select="
             ( ancestor-or-self::*[@xslt-version]/@xslt-version, 2.0 )[1]"/>

         <!--
             CONTEXT
             
             IF @context
               set context (@context)
             ELIF @test AND content
               set context (@test)
             ELIF count($result) = 1
               set context ($result)
             ELSE
               no context
         -->
         <xsl:choose>
            <xsl:when test="exists(@context)">
               <variable name="impl:with-context" select="true()"/>
               <variable name="impl:context" as="item()?">
                  <choose>
                     <!-- aka "count($x:result) le 1" (so if empty, context is empty too) -->
                     <when test="empty($x:result[2])">
                        <for-each select="$x:result">
                           <sequence select="{ @context }"/>
                        </for-each>
                     </when>
                     <!-- when count($x:result) ge 2 -->
                     <otherwise>
                        <!-- no context node set here -->
                        <sequence select="{ @context }"/>
                     </otherwise>
                  </choose>
               </variable>
            </xsl:when>
            <xsl:when test="exists(@test) and exists(node())">
               <variable name="impl:with-context" select="true()"/>
               <variable name="impl:context-tmp" as="item()*">
                  <choose>
                     <!-- aka "count($x:result) le 1" (so if empty, context is empty too) -->
                     <when test="empty($x:result[2])">
                        <for-each select="$x:result">
                           <sequence select="{ @test }"/>
                        </for-each>
                     </when>
                     <!-- when count($x:result) ge 2 -->
                     <otherwise>
                        <!-- no context node set here -->
                        <sequence select="{ @test }"/>
                     </otherwise>
                  </choose>
               </variable>
               <variable name="impl:context" as="item()?">
                  <choose>
                     <when test="$impl:context-tmp instance of node()+">
                        <document>
                           <sequence select="$impl:context-tmp"/>
                        </document>
                     </when>
                     <otherwise>
                        <sequence select="$impl:context-tmp"/>
                     </otherwise>
                  </choose>
               </variable>
            </xsl:when>
            <xsl:otherwise>
               <xsl:choose>
                  <xsl:when test="exists(@test)">
                     <variable name="impl:just-nodes" select="
                         $x:result instance of node()+"/>
                     <!-- aka "count($x:result) eq 1 or ..." -->
                     <variable name="impl:with-context" select="
                         exists($x:result) and empty($x:result[2]) or $impl:just-nodes"/>
                     <variable name="impl:context" as="item()?">
                        <choose>
                           <when test="$impl:just-nodes">
                              <document>
                                 <sequence select="$x:result"/>
                              </document>
                           </when>
                           <when test="$impl:with-context">
                              <sequence select="$x:result"/>
                           </when>
                           <otherwise/>
                        </choose>
                     </variable>
                  </xsl:when>
                  <xsl:otherwise>
                     <!-- aka "count($x:result) eq 1" -->
                     <variable name="impl:with-context" select="
                         exists($x:result) and empty($x:result[2])"/>
                     <variable name="impl:context" as="item()?">
                        <choose>
                           <when test="$impl:with-context">
                              <sequence select="$x:result"/>
                           </when>
                           <otherwise/>
                        </choose>
                     </variable>
                  </xsl:otherwise>
               </xsl:choose>
            </xsl:otherwise>
         </xsl:choose>

         <!--
             ASSERT & COMPARE
             
             IF content|@select
               compare (content|@select)
             ELIF @assert|@test
               assert (@assert|@test)
             ELSE
               compilation error

             every branch of this xsl:choose generates the variable $impl:successful,
             which is a boolean with the outcome of the test case (either passed or
             failed), and which is used later on in the generated code
         -->
         <xsl:choose>
            <xsl:when test="not($is-assert)">
               <!-- check there is exactly one of node()|@select -->
               <xsl:if test="exists(node()) and exists(@select)">
                  <xsl:message terminate="yes">
                     <xsl:text>ERROR in scenario "</xsl:text>
                     <xsl:value-of select="x:label(.)"/>
                     <xsl:text>": can't have both @select and context at the same time</xsl:text>
                  </xsl:message>
               </xsl:if>
               <xsl:apply-templates select="." mode="test:generate-variable-declarations">
                  <xsl:with-param name="var" select="'impl:expected'"/>
               </xsl:apply-templates>
               <variable name="impl:successful" as="xs:boolean" select="
                   test:deep-equal(
                     $impl:expected,
                     if ( $impl:with-context ) then $impl:context else $x:result,
                     { $version })"/>
            </xsl:when>
            <xsl:when test="exists(@assert|@test)">
               <!-- check there is exactly one of @assert|@test -->
               <xsl:if test="exists(@assert) and exists(@test)">
                  <xsl:message terminate="yes">
                     <xsl:text>ERROR in scenario "</xsl:text>
                     <xsl:value-of select="x:label(.)"/>
                     <xsl:text>": can't have both @context and @test at the same time</xsl:text>
                  </xsl:message>
               </xsl:if>
               <variable name="impl:assert" as="item()*">
                  <choose>
                     <when test="$impl:with-context">
                        <for-each select="$impl:context">
                           <sequence select="{ @assert|@test }"/>
                        </for-each>
                     </when>
                     <otherwise>
                        <sequence select="{ @assert|@test }"/>
                     </otherwise>
                  </choose>
               </variable>
               <if test="not($impl:assert instance of xs:boolean)">
                  <!-- TODO: For now, generate an error, make the test fails instead? -->
                  <message terminate="yes">
                     <xsl:text>ERROR in scenario "</xsl:text>
                     <xsl:value-of select="x:label(.)"/>
                     <!-- TODO: Generate the SequenceType of $impl:assert. -->
                     <xsl:text>": @assert|@test did not return a boolean</xsl:text>
                  </message>
               </if>
               <variable name="impl:successful" as="xs:boolean" select="$impl:assert"/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:message terminate="yes">
                  <xsl:text>ERROR in scenario "</xsl:text>
                  <xsl:value-of select="x:label(.)"/>
                  <xsl:text>": unknown expect combination</xsl:text>
                  <xsl:text>&#10;    content : </xsl:text>
                  <xsl:value-of select="exists(node())"/>
                  <xsl:text>&#10;    @context: </xsl:text>
                  <xsl:value-of select="exists(@context)"/>
                  <xsl:text>&#10;    @assert : </xsl:text>
                  <xsl:value-of select="exists(@assert)"/>
                  <xsl:text>&#10;    @select : </xsl:text>
                  <xsl:value-of select="exists(@select)"/>
                  <xsl:text>&#10;    @test   : </xsl:text>
                  <xsl:value-of select="exists(@test)"/>
               </xsl:message>
            </xsl:otherwise>
         </xsl:choose>
         <if test="not($impl:successful)">
            <message>
               <xsl:text>      FAILED</xsl:text>
            </message>
         </if>
      </xsl:if>
      <x:test>
         <xsl:choose>
            <xsl:when test="$pending-p">
               <xsl:attribute name="pending" select="$pending"/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:attribute name="successful" select="'{ $impl:successful }'"/>
            </xsl:otherwise>
         </xsl:choose>
         <xsl:sequence select="x:label(.)"/>
         <xsl:if test="not($pending-p)">
            <call-template name="test:report-value">
               <with-param name="value"        select="$x:result"/>
               <with-param name="wrapper-name" select="'x:result'"/>
               <with-param name="wrapper-ns"   select="'{ $xspec-ns }'"/>
            </call-template>
            <xsl:if test="not($is-assert)">
               <call-template name="test:report-value">
                  <with-param name="value"        select="$impl:expected"/>
                  <with-param name="wrapper-name" select="'x:expect'"/>
                  <with-param name="wrapper-ns"   select="'{ $xspec-ns }'"/>
               </call-template>
            </xsl:if>
         </xsl:if>
      </x:test>
   </template>
</xsl:template>

<!-- *** x:generate-declarations *** -->
<!-- Code to generate parameter declarations -->
<xsl:template match="x:param" mode="x:generate-declarations">
  <xsl:apply-templates select="." mode="test:generate-variable-declarations">
    <xsl:with-param name="var"  select="@name"/>
    <xsl:with-param name="type" select="'param'"/>
  </xsl:apply-templates>
</xsl:template>

<xsl:template match="x:variable" mode="x:generate-declarations">
  <xsl:apply-templates select="." mode="test:generate-variable-declarations">
    <xsl:with-param name="var"  select="@name"/>
    <xsl:with-param name="type" select="'variable'"/>
  </xsl:apply-templates>
</xsl:template>

<xsl:template match="x:space" mode="test:create-xslt-generator">
  <text><xsl:value-of select="." /></text>
</xsl:template>  
  

<!-- *** x:compile *** -->
<!-- Helper code for the tests -->

<xsl:template match="x:context" mode="x:setup-context">
   <xsl:variable name="context" as="element(x:context)">
      <x:context>
         <xsl:sequence select="@*" />
         <xsl:sequence select="node() except x:param" />
      </x:context>
   </xsl:variable>
   <xsl:apply-templates select="$context" mode="test:generate-variable-declarations">
      <xsl:with-param name="var" select="'impl:context'" />
   </xsl:apply-templates>
</xsl:template>  

<xsl:template match="x:context | x:param" mode="x:report">
  <xsl:element name="x:{local-name()}">
  	<xsl:apply-templates select="@*" mode="x:report" />
    <xsl:apply-templates mode="test:create-xslt-generator" />
  </xsl:element>
</xsl:template>
  
<xsl:template match="x:call" mode="x:report">
  <x:call>
    <xsl:copy-of select="@*" />
    <xsl:apply-templates mode="x:report" />
  </x:call>
</xsl:template>

<xsl:template match="@select" mode="x:report">
	<xsl:attribute name="select"
		select="replace(replace(., '\{', '{{'), '\}', '}}')" />
</xsl:template>

<xsl:template match="@*" mode="x:report">
	<xsl:sequence select="." />
</xsl:template>

<xsl:function name="x:label" as="node()?">
	<xsl:param name="labelled" as="element()" />
	<xsl:choose>
		<xsl:when test="exists($labelled/x:label)">
			<xsl:sequence select="$labelled/x:label" />
		</xsl:when>
		<xsl:otherwise>
			<x:label><xsl:value-of select="$labelled/@label" /></x:label>
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
