<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.w3.org/1999/XSL/TransformAlias"
    xmlns:local="urn:x-xspec:compiler:xproc:compile:compile-scenarios:local"
    xmlns:p="http://www.w3.org/ns/xproc" xmlns:wrap="urn:x-xspec:common:wrap"
    xmlns:x="http://www.jenitennison.com/xslt/xspec"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    exclude-result-prefixes="#all"
    version="3.0">

    <!--
        Generates the templates that perform the tests.
        Called during mode="local:compile-scenarios-or-expects" in
        compile-child-scenarios-or-expects.xsl.
    -->
   <xsl:template name="x:compile-scenario" as="element(xsl:template)+">
      <xsl:context-item as="element(x:scenario)" use="required" />

      <xsl:param name="call" as="element(x:call)?" required="yes" tunnel="yes" />
      <xsl:param name="reason-for-pending" as="xs:string?" required="yes" />
      <xsl:param name="run-sut-now" as="xs:boolean" required="yes" />

      <xsl:variable name="this-scenario" as="element(x:scenario)" select="."/>

      <xsl:variable name="local-preceding-vardecls" as="element()*" select="
            (x:param | x:variable)[following-sibling::x:call]
            | x:param[$run-sut-now]
            | x:variable[following-sibling::x:param][$run-sut-now]" />

      <!-- We have to create these error messages at this stage because before now
         we didn't have merged versions of the environment -->
      <xsl:if test="x:context">
         <xsl:message terminate="yes">
            <xsl:call-template name="x:prefix-diag-message">
               <xsl:with-param name="message" as="xs:string">
                  <xsl:text expand-text="yes">Can't use {x:xspec-name('context', .)} in a test suite for XProc.</xsl:text>
               </xsl:with-param>
            </xsl:call-template>
         </xsl:message>
      </xsl:if>
      <xsl:if test="$call/@template">
         <xsl:message terminate="yes">
            <xsl:call-template name="x:prefix-diag-message">
               <xsl:with-param name="message" as="xs:string">
                  <xsl:text expand-text="yes">{name($call)}/@template not supported for XProc.</xsl:text>
               </xsl:with-param>
            </xsl:call-template>
         </xsl:message>
      </xsl:if>
      <xsl:if test="$call/@function">
         <xsl:message terminate="yes">
            <xsl:call-template name="x:prefix-diag-message">
               <xsl:with-param name="message" as="xs:string">
                  <xsl:text expand-text="yes">{name($call)}/@function not supported for XProc.</xsl:text>
               </xsl:with-param>
            </xsl:call-template>
         </xsl:message>
      </xsl:if>
      <xsl:if test="$call[$run-sut-now][not(@step)]">
         <xsl:message terminate="yes">
            <xsl:call-template name="x:prefix-diag-message">
               <xsl:with-param name="message" as="xs:string">
                  <xsl:text expand-text="yes">{name($call)} must specify a step to call.</xsl:text>
               </xsl:with-param>
            </xsl:call-template>
         </xsl:message>
      </xsl:if>
      <xsl:if test="x:expect and empty($call)">
         <xsl:message terminate="yes">
            <xsl:call-template name="x:prefix-diag-message">
               <xsl:with-param name="message" as="xs:string">
                  <!-- Use x:xspec-name() for displaying the element names with the prefix preferred by
                     the user -->
                  <xsl:text expand-text="yes">There are {x:xspec-name('expect', .)} but no {x:xspec-name('call', .)} has been given.</xsl:text>
               </xsl:with-param>
            </xsl:call-template>
         </xsl:message>
      </xsl:if>

      <xsl:element name="xsl:template" namespace="{$x:xsl-namespace}">
         <xsl:attribute name="name" select="x:known-UQName('x:' || @id)" />
         <xsl:attribute name="as" select="'element(' || x:known-UQName('x:scenario') || ')'" />

         <!-- Runtime context item of the template being generated at this compile time must be
            absent (xspec/xspec#423). Even when the template being generated at this compile time is
            called with a context item at run time, it must be removed by
            xsl:context-item[@use="absent"]. -->
         <xsl:element name="xsl:context-item" namespace="{$x:xsl-namespace}">
            <xsl:attribute name="use" select="'absent'" />
         </xsl:element>

         <xsl:for-each select="accumulator-before('stacked-vardecls-distinct-uqnames')">
            <param name="{.}" as="item()*" required="yes" />
         </xsl:for-each>

         <message>
            <xsl:if test="exists($reason-for-pending)">
               <xsl:text>PENDING: </xsl:text>
               <xsl:for-each select="normalize-space($reason-for-pending)[.]">
                  <xsl:text expand-text="yes">({.}) </xsl:text>
               </xsl:for-each>
            </xsl:if>
            <xsl:if test="parent::x:scenario">
               <xsl:text>..</xsl:text>
            </xsl:if>
            <xsl:value-of select="normalize-space(x:label(.))" />
         </message>

         <!-- <x:scenario> -->
         <xsl:element name="xsl:element" namespace="{$x:xsl-namespace}">
            <xsl:attribute name="name" select="local-name()" />
            <xsl:attribute name="namespace" select="namespace-uri()" />

            <xsl:variable name="scenario-attributes" as="attribute()+">
               <xsl:sequence select="@id" />
               <xsl:attribute name="xspec" select="(@original-xspec, @xspec)[1]" />
               <xsl:sequence select="x:pending-attribute-from-reason($reason-for-pending)" />
            </xsl:variable>
            <xsl:apply-templates select="$scenario-attributes" mode="x:node-constructor" />

            <xsl:apply-templates select="x:label(.)" mode="x:node-constructor" />

            <xsl:call-template name="x:timestamp">
               <xsl:with-param name="event" select="'start'" />
            </xsl:call-template>

            <!-- Handle local preceding variable declarations and x:call in document
               order, instead of x:call first and variable declarations second. -->
            <xsl:for-each select="$local-preceding-vardecls | x:call">
               <xsl:choose>
                  <xsl:when test="self::x:call">
                     <!-- Copy the input to the test result report XML -->
                     <!-- Undeclare the default namespace in the wrapper element, because
                        x:param/@select may use the default namespace such as xs:QName('foo'). -->
                     <xsl:call-template name="x:wrap-node-constructors-and-undeclare-default-ns">
                        <xsl:with-param name="wrapper-name" select="'input-wrap'" />
                        <xsl:with-param name="node-constructors" as="element(xsl:element)">
                           <xsl:apply-templates select="." mode="x:node-constructor" />
                        </xsl:with-param>
                     </xsl:call-template>

                  </xsl:when>

                  <xsl:when test=". intersect $local-preceding-vardecls">
                     <!-- Handle local preceding variable declarations. The other local variable
                        declarations are handled in mode="local:invoke-compiled-scenarios-or-expects"
                        in invoke-compiled-child-scenarios-or-expects.xsl. -->
                     <xsl:apply-templates select=".[x:reason-for-pending(.) => empty()]"
                        mode="x:declare-variable" />
                  </xsl:when>

                  <xsl:otherwise>
                     <xsl:message terminate="yes">
                        <xsl:call-template name="x:prefix-diag-message">
                           <xsl:with-param name="message" select="'Unhandled'" />
                        </xsl:call-template>
                     </xsl:message>
                  </xsl:otherwise>
               </xsl:choose>
            </xsl:for-each>

            <xsl:if test="$run-sut-now">
               <variable name="{x:known-UQName('x:result')}" as="item()*">
                  <!-- Set up variables containing the input and option values, but skip
                     elements with p:document children because p:document will be copied to
                     the test-case step (XProc) instead of being evaluated here in XSLT. -->
                  <xsl:for-each select="$call/(x:input | x:option)[x:evaluate-in(.) eq 'xslt']">
                     <xsl:apply-templates select="." mode="x:declare-variable">
                        <xsl:with-param name="comment" select="concat(@port (: x:input :), @name (: x:option :), ' ', local-name())" />
                     </xsl:apply-templates>
                  </xsl:for-each>
                  <!-- Set up variable for the generated XProc step that p:run will use to invoke the test target -->
                  <xsl:for-each select="$call">
                     <variable name="{x:known-UQName('impl:test-case-step-based-on-x-call')}"
                        as="element()" expand-text="no">
                        <!-- expand-text="no" is so that XSLT TVT behavior doesn't interfere with
                           TVT behavior occurring in XProc when the test-case step is evaluated.
                           Users can still have x:input/p:document/p:pipeinfo[@expand-text='yes'],
                           for instance, and XSpec preserves curly braces in p:pipeinfo for
                           evaluation by the XProc processor. -->
                        <xsl:call-template name="test-case-step-based-on-x-call">
                           <xsl:with-param name="parent-scenario" select="$this-scenario"/>
                        </xsl:call-template>
                     </variable>
                     <variable name="{x:known-UQName('impl:options-for-step-function')}" as="map(*)">
                        <xsl:namespace name="wrap" select="'urn:x-xspec:common:wrap'"/>
                        <xsl:attribute name="select">
                           <xsl:call-template name="options-for-step-function">
                              <xsl:with-param name="parent-scenario" select="$this-scenario"/>
                           </xsl:call-template>
                        </xsl:attribute>
                     </variable>
                  </xsl:for-each>
                  <!-- Additional error checking -->
                  <xsl:sequence select="local:p-input-error-checking($call, $this-scenario)"/>

                  <xsl:variable name="invocation-type" as="xs:string">call-step</xsl:variable>

                  <!-- Enter SUT -->
                  <xsl:choose>
                     <!-- TODO: After confirming that external transformation doesn't apply to
                        XProc, remove the commented-out xsl:when and xsl:otherwise, and elevate
                        the remaining xsl:when

                     <xsl:when test="$is-external">
                        <!-/- Set up the $impl:transform-options variable -/->
                        <xsl:call-template name="x:transform-options">
                           <xsl:with-param name="invocation-type" select="$invocation-type" />
                        </xsl:call-template>

                        <!-/- Generate XSLT elements which perform entering SUT -/->
                        <xsl:variable name="enter-sut" as="element()+">
                           <xsl:call-template name="x:enter-sut">
                              <xsl:with-param name="instruction" as="element(xsl:sequence)">
                                 <sequence
                                    select="transform(${x:known-UQName('impl:transform-options')})?output" />
                              </xsl:with-param>
                           </xsl:call-template>
                        </xsl:variable>

                        <!-/- Invoke transform() -/->
                        <xsl:sequence select="$enter-sut" />
                     </xsl:when>
                     -->

                     <xsl:when test="$invocation-type eq 'call-step'">
                        <!-- Create the step call. Don't call x:enter-sut here because the
                           try/catch structure goes in the XProc test-case step, not XSLT. -->
                        <sequence>
                           <!-- The step being called may use namespace prefixes for
                              parsing the input/option values -->
                           <xsl:sequence select="x:copy-of-namespaces($call)" />
                           <xsl:attribute name="select"
                              select="concat(
                              x:step-call-text($call),
                              '(''map-of-outputs'')'
                              )"/>
                        </sequence>
                     </xsl:when>

                     <xsl:otherwise>
                        <!-- TODO: Adapt to a new error reporting facility (above usages too). -->
                        <xsl:message terminate="yes">
                           <xsl:call-template name="x:prefix-diag-message">
                              <xsl:with-param name="message" select="'cannot happen.'" />
                           </xsl:call-template>
                        </xsl:message>
                     </xsl:otherwise>
                  </xsl:choose>
               </variable>

               <xsl:call-template name="x:call-report-sequence">
                  <xsl:with-param name="sequence-variable-eqname"
                     select="x:known-UQName('x:result')" />
               </xsl:call-template>
               <xsl:comment> invoke each compiled x:expect </xsl:comment>
            </xsl:if>

            <xsl:call-template name="x:invoke-compiled-child-scenarios-or-expects">
               <xsl:with-param name="handled-child-vardecls" select="$local-preceding-vardecls" />
            </xsl:call-template>

            <xsl:call-template name="x:timestamp">
               <xsl:with-param name="event" select="'end'" />
            </xsl:call-template>

         <!-- </x:scenario> -->
         </xsl:element>
      </xsl:element>

      <xsl:call-template name="x:compile-child-scenarios-or-expects" />
   </xsl:template>

   <!-- Returns a text node of a function call expression that calls the step runner.
       The step runner is an XProc step, but we call it as a step function. -->
   <xsl:function name="x:step-call-text" as="text()">
      <xsl:param name="call" as="element(x:call)"/>

      <xsl:value-of expand-text="yes">
         <xsl:text>{x:known-UQName('impl:step-runner')}</xsl:text>
         <xsl:text>(</xsl:text>
         <xsl:text>(: { $call/@step } :)</xsl:text>
         <xsl:text>${x:known-UQName('impl:test-case-step-based-on-x-call')}</xsl:text>
         <xsl:text>, </xsl:text>
         <xsl:text>${x:known-UQName('impl:options-for-step-function')}</xsl:text>
         <xsl:text>)</xsl:text>
      </xsl:value-of>
   </xsl:function>

   <!-- Indicates whether an x:input or x:option element will be evaluated
      in XProc or XSLT -->
   <xsl:function name="x:evaluate-in" as="xs:string">
      <xsl:param name="element" as="element()"/>
      <xsl:choose>
         <xsl:when test="exists($element/p:document)">
            <xsl:sequence select="'xproc'"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:sequence select="'xslt'"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>

   <!--
      Local templates and functions
   -->

   <!-- Generates text for creating a map of options to pass to the impl:step-runner
      XProc step when calling it from XSLT as a step function. -->
   <xsl:template name="options-for-step-function" as="text()">
      <xsl:context-item as="element(x:call)" use="required"/>
      <xsl:param name="parent-scenario" as="element(x:scenario)"
         required="yes"/>
      <xsl:value-of>
         <xsl:text>map{</xsl:text>
         <xsl:text>'map-of-inputs':</xsl:text>
         <xsl:call-template name="input-map-text">
            <xsl:with-param name="parent-scenario" select="$parent-scenario"/>
         </xsl:call-template>
         <xsl:text>,</xsl:text>
         <xsl:text>'map-of-options':</xsl:text>
         <xsl:call-template name="option-map-text">
            <xsl:with-param name="parent-scenario" select="$parent-scenario"/>
         </xsl:call-template>
         <xsl:text>}</xsl:text>
      </xsl:value-of>
   </xsl:template>

   <!-- Generates text for creating a map of input documents, referencing XSLT variables
      whose declarations were already generated based on x:input elements. -->
   <xsl:template name="input-map-text" as="text()">
      <xsl:context-item as="element(x:call)" use="required"/>
      <xsl:param name="parent-scenario" as="element(x:scenario)" required="yes">
      </xsl:param>

      <!-- Check for duplicate input ports -->
      <xsl:sequence select="
            local:error-for-duplicates(
            local:input-dup-port-error-string(.),
            $parent-scenario/x:call
            )"/>
      
      <xsl:value-of>
         <xsl:text>map{</xsl:text>
         <xsl:iterate select="x:input[x:evaluate-in(.) eq 'xslt']">
            <xsl:param name="separator" as="xs:string" select="''"/>
            <xsl:variable name="port-name" as="xs:string" select="@port"/>
            <!-- Reason for wrap:unwrap-text-nodes: A text node wrapped in a document node
               normally has content type text/plain, but if you put that document node in a
               map and pass that to a step that retrieves the document from the map, the
               retrieved document's content type is application/xml. Putting the bare
               text node into the map doesn't have that behavior, and downstream steps will
               wrap it in a text node *without* changing the content type. -->
            <xsl:value-of expand-text="yes">{$separator}'{$port-name}': wrap:unwrap-text-nodes(${
               x:variable-UQName(.)})</xsl:value-of>
            <xsl:next-iteration>
               <!-- Add comma between adjacent map entries -->
               <xsl:with-param name="separator" select="', '"/>
            </xsl:next-iteration>
         </xsl:iterate>
         <xsl:text>}</xsl:text>
      </xsl:value-of>
   </xsl:template>

   <!-- Generates text for creating a map of option values, referencing XSLT variables
      whose declarations were already generated based on x:option elements. -->
   <!-- This template is like "input-map-text", except the error checking and
      the need to resolve qualified names -->
   <xsl:template name="option-map-text" as="text()">
      <xsl:context-item as="element(x:call)" use="required"/>
      <xsl:param name="parent-scenario" as="element(x:scenario)" required="yes">
      </xsl:param>

      <!-- Check for duplicate option names -->
      <xsl:sequence select="
         local:error-for-duplicates(
         local:option-dup-name-error-string(.),
         $parent-scenario/x:call
         )"/>

      <xsl:value-of>
         <xsl:text>map{</xsl:text>
         <xsl:iterate select="x:option[x:evaluate-in(.) eq 'xslt']">
            <xsl:param name="separator" as="xs:string" select="''"/>
            <xsl:variable name="resolved-option-QName" as="xs:string"
               select="x:UQName-from-EQName-ignoring-default-ns(@name, .)"/>
            <xsl:value-of expand-text="yes">{$separator}'{$resolved-option-QName}': ${
               x:variable-UQName(.)}</xsl:value-of>
            <xsl:next-iteration>
               <!-- Add comma between adjacent map entries -->
               <xsl:with-param name="separator" select="', '"/>
            </xsl:next-iteration>
         </xsl:iterate>
         <xsl:text>}</xsl:text>
      </xsl:value-of>
   </xsl:template>

   <!-- Returns an error string if the given element has duplicate x:input/@port -->
   <!-- This function is adapted from local:param-dup-name-error-string in
      base/compile/compile-child-scenarios-or-expects.xsl -->
   <xsl:function name="local:input-dup-port-error-string" as="xs:string?">
      <xsl:param name="owner" as="element(x:call)" />
      
      <xsl:variable name="port-names" as="xs:string*" select="$owner/x:input/@port" />
      <xsl:for-each select="$port-names[subsequence($port-names, 1, position() - 1) = .][1]">
         <xsl:text expand-text="yes">Duplicate input port '{.}' used in {name($owner)}.</xsl:text>
      </xsl:for-each>
   </xsl:function>

   <!-- Returns an error string if the given element has duplicate x:option/@name -->
   <!-- This function is adapted from local:param-dup-name-error-string in
      base/compile/compile-child-scenarios-or-expects.xsl -->
   <xsl:function name="local:option-dup-name-error-string" as="xs:string?">
      <xsl:param name="owner" as="element(x:call)" />
      
      <xsl:variable name="uqnames" as="xs:string*"
         select="$owner/x:option/@name ! x:UQName-from-EQName-ignoring-default-ns(., parent::x:option)" />
      <xsl:for-each select="$uqnames[subsequence($uqnames, 1, position() - 1) = .][1]">
         <xsl:text expand-text="yes">Duplicate option name, {.}, used in {name($owner)}.</xsl:text>
      </xsl:for-each>
   </xsl:function>

   <!-- Raises an error if a previously computed error string is not an empty sequence -->
   <xsl:function name="local:error-for-duplicates" as="empty-sequence()">
      <xsl:param name="error-string" as="xs:string?"/>
      <xsl:param name="call" as="element(x:call)"/>
      <xsl:if test="$error-string">
         <xsl:for-each select="$call">
            <xsl:message terminate="yes">
               <xsl:call-template name="x:prefix-diag-message">
                  <xsl:with-param name="message" select="$error-string"/>
               </xsl:call-template>
            </xsl:message>
         </xsl:for-each>
      </xsl:if>
   </xsl:function>

   <!-- Error/warning checking based on p:input declaration in test target, largely to
      preempt a non-specific error message like "The pipeline could not be compiled."
      from the generated step. -->
   <xsl:function name="local:p-input-error-checking" as="empty-sequence()">
      <xsl:param name="call" as="element(x:call)"/>
      <xsl:param name="parent-scenario" as="element(x:scenario)"/>
      <xsl:variable name="step-declaration" as="element(p:declare-step)"
         select="x:step-declaration($call, $parent-scenario)"/>
      <xsl:variable name="declared-inputs" as="element(p:input)*"
         select="$step-declaration/p:input"/>
      <xsl:variable name="declared-options" as="element(p:option)*"
         select="$step-declaration/p:option"/>
      <xsl:variable name="declared-nonstatic-step-option-UQNames" as="xs:string*"
         select="$declared-options[not(@static='true')] ! x:UQName-from-EQName-ignoring-default-ns(@name, .)"/>
      <xsl:variable name="declared-static-step-option-UQNames" as="xs:string*"
         select="$declared-options[@static='true'] ! x:UQName-from-EQName-ignoring-default-ns(@name, .)"/>

      <xsl:for-each select="$call/x:input[not(@port/string() = $declared-inputs/@port/string())]">
         <xsl:variable name="unknown-port" as="xs:string" select="@port"/>
         <xsl:for-each select="$parent-scenario/x:call">
            <xsl:message terminate="yes">
               <xsl:call-template name="x:prefix-diag-message">
                  <xsl:with-param name="message">
                     <xsl:text expand-text="yes">Step of type '{ $call/@step }' has no port named '{ $unknown-port }'.</xsl:text>
                  </xsl:with-param>
               </xsl:call-template>
            </xsl:message>
         </xsl:for-each>
      </xsl:for-each>     
      <xsl:for-each select="$call/x:option">
         <xsl:variable name="option-name" as="xs:string" select="@name"/>
         <xsl:variable name="option-UQName" as="xs:string"
            select="x:UQName-from-EQName-ignoring-default-ns($option-name, .)"/>
         <xsl:if test="($option-UQName = $declared-static-step-option-UQNames) or
            exists(key('static-library-options', $option-UQName, $xproc-input-tree))">
            <xsl:for-each select="$parent-scenario/x:call">
               <xsl:message terminate="yes">
                  <xsl:call-template name="x:prefix-diag-message">
                     <xsl:with-param name="message">
                        <xsl:text expand-text="yes">Cannot specify option '{ $option-name }' because it is static.</xsl:text>
                     </xsl:with-param>
                  </xsl:call-template>
               </xsl:message>
            </xsl:for-each>            
         </xsl:if>
         <xsl:if test="not($option-UQName = $declared-nonstatic-step-option-UQNames)">
            <xsl:for-each select="$parent-scenario/x:call">
               <xsl:message terminate="yes">
                  <xsl:call-template name="x:prefix-diag-message">
                     <xsl:with-param name="message">
                        <xsl:text expand-text="yes">Step of type '{ $call/@step }' has no option named '{ $option-name }'.</xsl:text>
                     </xsl:with-param>
                  </xsl:call-template>
               </xsl:message>
            </xsl:for-each>            
         </xsl:if>
      </xsl:for-each>
      <xsl:for-each select="$declared-inputs">
         <xsl:variable name="p-input" as="element(p:input)" select="."/>
         <xsl:variable name="x-input" as="element(x:input)*"
            select="$call/x:input[@port eq string($p-input/@port)]"/>
         <xsl:choose>
            <xsl:when test="empty($x-input) and empty($p-input/@x:has-default-input)">
               <xsl:for-each select="$parent-scenario/x:call">
                  <xsl:message terminate="yes">
                     <xsl:call-template name="x:prefix-diag-message">
                        <xsl:with-param name="message">
                           <xsl:text expand-text="yes">Missing x:input for port '{ $p-input/@port }', which declares no default.</xsl:text>
                        </xsl:with-param>
                     </xsl:call-template>
                  </xsl:message>
               </xsl:for-each>
            </xsl:when>
            <xsl:when test="exists($p-input/ancestor-or-self::*/@use-when)">
               <xsl:for-each select="$parent-scenario">
                  <xsl:message>
                     <xsl:call-template name="x:prefix-diag-message">
                        <xsl:with-param name="level" select="'WARNING'" />
                        <xsl:with-param name="message">
                           <xsl:text expand-text="yes">Declaration of port {
                                    $x-input/@port} is under @use-when, which XSpec assumes is true.</xsl:text>
                        </xsl:with-param>
                     </xsl:call-template>
                  </xsl:message>
               </xsl:for-each>
            </xsl:when>
         </xsl:choose>
      </xsl:for-each>
   </xsl:function>

</xsl:stylesheet>