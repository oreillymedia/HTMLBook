<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:x="http://www.jenitennison.com/xslt/xspec"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                exclude-result-prefixes="#all"
                version="3.0">

   <!--
      Generates the functions that perform the tests.
      Called during mode="local:compile-scenarios-or-expects" in
      compile-child-scenarios-or-expects.xsl.
   -->
   <xsl:template name="x:compile-scenario" as="node()+">
      <xsl:context-item as="element(x:scenario)" use="required" />

      <xsl:param name="call" as="element(x:call)?" required="yes" tunnel="yes" />
      <xsl:param name="context" as="element(x:context)?" required="yes" tunnel="yes" />
      <xsl:param name="reason-for-pending" as="xs:string?" required="yes" />
      <xsl:param name="run-sut-now" as="xs:boolean" required="yes" />

      <xsl:variable name="local-preceding-vardecls" as="element(x:variable)*"
         select="x:variable[following-sibling::x:call]" />

      <xsl:if test="$context">
         <xsl:message terminate="yes">
            <xsl:call-template name="x:prefix-diag-message">
               <xsl:with-param name="message" as="xs:string">
                  <xsl:text expand-text="yes">{name($context)} not supported for XQuery</xsl:text>
               </xsl:with-param>
            </xsl:call-template>
         </xsl:message>
      </xsl:if>
      <xsl:if test="$call/@template">
         <xsl:message terminate="yes">
            <xsl:call-template name="x:prefix-diag-message">
               <xsl:with-param name="message" as="xs:string">
                  <xsl:text expand-text="yes">{name($call)}/@template not supported for XQuery</xsl:text>
               </xsl:with-param>
            </xsl:call-template>
         </xsl:message>
      </xsl:if>
      <xsl:if test="$call/@step">
         <xsl:message terminate="yes">
            <xsl:call-template name="x:prefix-diag-message">
               <xsl:with-param name="message" as="xs:string">
                  <xsl:text expand-text="yes">{name($call)}/@step not supported for XQuery</xsl:text>
               </xsl:with-param>
            </xsl:call-template>
         </xsl:message>
      </xsl:if>
      <xsl:if test="$run-sut-now">
         <xsl:call-template name="x:check-param-max-position" />
      </xsl:if>
      <xsl:if test="x:expect and empty($call)">
         <xsl:message terminate="yes">
            <xsl:call-template name="x:prefix-diag-message">
               <xsl:with-param name="message" as="xs:string">
                  <!-- Use x:xspec-name() for displaying the element names with the prefix preferred by
                     the user -->
                  <xsl:text expand-text="yes">There are {x:xspec-name('expect', .)} but no {x:xspec-name('call', .)}</xsl:text>
               </xsl:with-param>
            </xsl:call-template>
         </xsl:message>
      </xsl:if>

      <!--
        declare function local:...(...)
        {
      -->
      <xsl:text>&#10;(: generated from the x:scenario element :)</xsl:text>
      <xsl:text expand-text="yes">&#10;declare function local:{@id}(&#x0A;</xsl:text>

      <!-- Function parameters. Their order must be stable, because this is a function. -->
      <xsl:for-each select="accumulator-before('stacked-vardecls-distinct-uqnames')">
         <xsl:text expand-text="yes">${.} as item()*</xsl:text>
         <xsl:if test="position() ne last()">
            <xsl:text>,</xsl:text>
         </xsl:if>
         <xsl:text>&#x0A;</xsl:text>
      </xsl:for-each>

      <xsl:text expand-text="yes">) as element({x:known-UQName('x:scenario')})&#x0A;</xsl:text>

      <!-- Start of the function body -->
      <xsl:text>{&#x0A;</xsl:text>

      <!-- If there are variable declarations before x:call, handle them here followed by "return".
         The other local variable declarations are handled in
         mode="local:invoke-compiled-scenarios-or-expects" in
         invoke-compiled-child-scenarios-or-expects.xsl. -->
      <xsl:sequence>
         <xsl:apply-templates select="$local-preceding-vardecls[x:reason-for-pending(.) => empty()]"
            mode="x:declare-variable" />
         <xsl:on-non-empty>
            <xsl:text>return&#x0A;</xsl:text>
         </xsl:on-non-empty>
      </xsl:sequence>

      <!-- <x:scenario> -->
      <xsl:text>element { </xsl:text>
      <xsl:value-of select="QName(namespace-uri(), local-name()) => x:QName-expression()" />
      <xsl:text> } {&#x0A;</xsl:text>

      <xsl:call-template name="x:zero-or-more-node-constructors">
         <xsl:with-param name="nodes" as="node()+">
            <xsl:sequence select="@id, @xspec" />
            <xsl:sequence select="x:pending-attribute-from-reason($reason-for-pending)" />

            <xsl:sequence select="x:label(.)" />
         </xsl:with-param>
      </xsl:call-template>

      <xsl:if test="$measure-time">
         <xsl:text>,&#x0A;</xsl:text>
         <xsl:call-template name="x:timestamp">
            <xsl:with-param name="event" select="'start'" />
         </xsl:call-template>
      </xsl:if>

      <!-- Copy the input to the test result report XML -->
      <xsl:for-each select="x:call">
         <xsl:text>,&#x0A;</xsl:text>

         <!-- Undeclare the default namespace in the wrapper element, because x:param/@select may
            use the default namespace such as xs:QName('foo'). -->
         <xsl:call-template name="x:wrap-node-constructors-and-undeclare-default-ns">
            <xsl:with-param name="wrapper-name" select="'input-wrap'" />
            <xsl:with-param name="node-constructors" as="node()+">
               <xsl:apply-templates select="." mode="x:node-constructor" />
            </xsl:with-param>
         </xsl:call-template>
      </xsl:for-each>

      <xsl:sequence>
         <xsl:on-non-empty>
            <xsl:text>,&#x0A;</xsl:text>
         </xsl:on-non-empty>

         <xsl:variable name="variable-name-of-actual-result-report" as="xs:string?"
            select="'local:actual-result-report'[$run-sut-now]" />

         <xsl:if test="$run-sut-now">
            <!-- Set up variables containing the parameter values -->
            <xsl:for-each select="$call/x:param">
               <xsl:apply-templates select="." mode="x:declare-variable">
                  <xsl:with-param name="comment" select="@name ! ('$' || .)" />
               </xsl:apply-templates>
            </xsl:for-each>

            <xsl:text expand-text="yes">let ${x:known-UQName('x:result')} as item()* := (&#x0A;</xsl:text>
            <xsl:call-template name="x:enter-sut">
               <xsl:with-param name="instruction" as="text()+">
                  <xsl:sequence select="x:function-call-text($call)" />
                  <xsl:text>&#x0A;</xsl:text>
               </xsl:with-param>
            </xsl:call-template>
            <xsl:text>)&#x0A;</xsl:text>

            <xsl:text expand-text="yes">let ${$variable-name-of-actual-result-report} := </xsl:text>
            <xsl:call-template name="x:call-report-sequence">
               <xsl:with-param name="sequence-variable-eqname" select="x:known-UQName('x:result')" />
            </xsl:call-template>
            <xsl:text>&#x0A;</xsl:text>

            <xsl:text>&#x0A;</xsl:text>
            <xsl:text>(: invoke each compiled x:expect :)&#x0A;</xsl:text>
         </xsl:if>

         <xsl:call-template name="x:invoke-compiled-child-scenarios-or-expects">
            <xsl:with-param name="handled-child-vardecls" select="$local-preceding-vardecls" />
            <xsl:with-param name="tunnel_variable-name-of-actual-result-report"
               select="$variable-name-of-actual-result-report" tunnel="yes" />
         </xsl:call-template>
      </xsl:sequence>

      <xsl:if test="$measure-time">
         <xsl:text>,&#x0A;</xsl:text>
         <xsl:call-template name="x:timestamp">
            <xsl:with-param name="event" select="'end'" />
         </xsl:call-template>
      </xsl:if>

      <!-- </x:scenario> -->
      <xsl:text>}&#x0A;</xsl:text>

      <!-- End of the function -->
      <xsl:text>};&#x0A;</xsl:text>

      <xsl:call-template name="x:compile-child-scenarios-or-expects" />
   </xsl:template>

</xsl:stylesheet>