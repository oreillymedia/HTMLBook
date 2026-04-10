<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:x="http://www.jenitennison.com/xslt/xspec"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                exclude-result-prefixes="#all"
                version="3.0">

   <!--
      Generate an XQuery function from the expect element.
      
      This generated function, when called, checks the expectation against the actual result of the
      test and returns the corresponding x:test element for the XML report.
   -->
   <xsl:template name="x:compile-expect" as="node()+">
      <xsl:context-item as="element(x:expect)" use="required" />

      <xsl:param name="reason-for-pending" as="xs:string?" required="yes" />

      <!-- URIQualifiedNames of the parameters of the function being generated.
         Their order must be stable, because they are function parameters. -->
      <xsl:param name="param-uqnames" as="xs:string*" required="yes" />

      <!--
        declare function local:...($t:result as item()*)
        {
      -->
      <xsl:text>&#10;(: generated from the x:expect element :)</xsl:text>
      <xsl:text expand-text="yes">&#10;declare function local:{@id}(&#x0A;</xsl:text>
      <xsl:for-each select="$param-uqnames">
         <xsl:text expand-text="yes">${.} as item()*</xsl:text>
         <xsl:if test="position() ne last()">
            <xsl:text>,</xsl:text>
         </xsl:if>
         <xsl:text>&#x0A;</xsl:text>
      </xsl:for-each>
      <xsl:text expand-text="yes">) as element({x:known-UQName('x:test')})&#x0A;</xsl:text>

      <!-- Start of the function body -->
      <xsl:text>{&#x0A;</xsl:text>

      <xsl:if test="empty($reason-for-pending)">
         <!-- Set up the $local:expected variable -->
         <xsl:apply-templates select="." mode="x:declare-variable">
            <xsl:with-param name="comment" select="'expected result'" />
         </xsl:apply-templates>

         <!-- Flags for deq:deep-equal() enclosed in ''. -->
         <xsl:variable name="deep-equal-flags" as="xs:string">''</xsl:variable>

         <xsl:text>(: flag if @result-type is present but $x:result is not the right type :)&#x0A;</xsl:text>
         <xsl:text expand-text="yes">let $local:result-type-mismatch as xs:boolean := {x:result-type-mismatch-condition(.)}&#x0A;</xsl:text>

         <xsl:choose>
            <xsl:when test="@test">
               <!-- $local:test-items
                  TODO: Wrap $x:result in a document node if possible -->
               <xsl:text expand-text="yes">let $local:test-items as item()* := ${x:known-UQName('x:result')}&#x0A;</xsl:text>

               <!-- $local:test-result
                  TODO: Evaluate @test in the context of $local:test-items, if
                    $local:test-items is a node -->
               <xsl:text>let $local:test-result as item()* (: evaluate the predicate :) := (&#x0A;</xsl:text>
               <xsl:text>if ($local:result-type-mismatch)&#x0A;</xsl:text>
               <xsl:text>then ((: In case of data type mismatch, do not process @test :))&#x0A;</xsl:text>
               <xsl:text expand-text="yes">else {x:disable-escaping(@test)}&#x0A;</xsl:text>
               <xsl:text>)&#x0A;</xsl:text>

               <!-- $local:boolean-test -->
               <xsl:text>let $local:boolean-test as xs:boolean := ($local:test-result instance of xs:boolean)&#x0A;</xsl:text>

               <!-- $local:successful -->
               <xsl:text>let $local:successful as xs:boolean (: did the test pass? :) := (&#x0A;</xsl:text>
               <xsl:text>if ($local:result-type-mismatch)&#x0A;</xsl:text>
               <xsl:text>then false()&#x0A;</xsl:text>
               <xsl:text>else if ($local:boolean-test) then&#x0A;</xsl:text>
               <xsl:choose>
                  <xsl:when test="x:has-comparison(.)">
                     <xsl:text expand-text="yes">error((), {x:boolean-with-comparison(.) => x:quote-with-apos()})&#x0A;</xsl:text>
                  </xsl:when>
                  <xsl:otherwise>
                     <xsl:text>boolean($local:test-result)&#x0A;</xsl:text>
                  </xsl:otherwise>
               </xsl:choose>
               <xsl:text>else&#x0A;</xsl:text>
               <xsl:choose>
                  <xsl:when test="x:has-comparison(.)">
                     <xsl:text expand-text="yes">{x:known-UQName('deq:deep-equal')}(${x:variable-UQName(.)}, $local:test-result, {$deep-equal-flags})&#x0A;</xsl:text>
                  </xsl:when>
                  <xsl:otherwise>
                     <xsl:text expand-text="yes">error((), {x:non-boolean-without-comparison(.) => x:quote-with-apos()})&#x0A;</xsl:text>
                  </xsl:otherwise>
               </xsl:choose>
               <xsl:text>)&#x0A;</xsl:text>
            </xsl:when>

            <xsl:otherwise>
               <!-- $local:successful -->
               <xsl:text>let $local:successful as xs:boolean :=&#x0A;</xsl:text>
               <xsl:text>not($local:result-type-mismatch) and&#x0A;</xsl:text>
               <xsl:text expand-text="yes">{x:known-UQName('deq:deep-equal')}(${x:variable-UQName(.)}, ${x:known-UQName('x:result')}, {$deep-equal-flags})&#x0A;</xsl:text>
            </xsl:otherwise>
         </xsl:choose>

         <xsl:text>return&#x0A;</xsl:text>
      </xsl:if>

      <!-- <x:test> -->
      <xsl:text>element { </xsl:text>
      <xsl:value-of select="QName(namespace-uri(), 'test') => x:QName-expression()" />
      <xsl:text> } {&#x0A;</xsl:text>

      <xsl:call-template name="x:zero-or-more-node-constructors">
         <xsl:with-param name="nodes" as="node()+">
            <xsl:sequence select="@id" />
            <xsl:sequence select="x:pending-attribute-from-reason($reason-for-pending)" />
         </xsl:with-param>
      </xsl:call-template>
      <xsl:text>,&#x0A;</xsl:text>

      <xsl:if test="empty($reason-for-pending)">
         <!-- @successful must be evaluated at run time -->
         <xsl:text>attribute { QName('', 'successful') } { $local:successful },&#x0A;</xsl:text>
      </xsl:if>

      <xsl:apply-templates select="x:label(.)" mode="x:node-constructor" />

      <!-- Report -->
      <xsl:if test="empty($reason-for-pending)">
         <xsl:text>,&#x0A;</xsl:text>

         <!-- Record data the report will need, based on outcomes fully known only at run time. -->
         <xsl:if test="@result-type">
            <xsl:text>if ( $local:result-type-mismatch )&#x0A;</xsl:text>
            <!-- For failure due to data type mismatch, record the "instance of" expression. -->
            <xsl:text>then (</xsl:text>
            <xsl:call-template name="x:report-test-attribute">
               <xsl:with-param name="attribute-local-name" select="'result-type'"/>
            </xsl:call-template>
            <xsl:text>)&#x0A;</xsl:text>
            <xsl:text>else&#x0A;</xsl:text>
         </xsl:if>
         <xsl:if test="@test">
            <xsl:text>if ( $local:boolean-test )&#x0A;</xsl:text>
            <!-- For failure due to boolean x:expect/@test, record @test. -->
            <xsl:text>then (</xsl:text>
            <xsl:call-template name="x:report-test-attribute" />
            <xsl:text>)&#x0A;</xsl:text>
            <xsl:text expand-text="yes">else if (not($local:boolean-test))&#x0A;</xsl:text>
            <!-- For failure due to non-boolean x:expect/@test, record @test and the result
               of evaluating @test against $x:result. -->
            <xsl:text>then (</xsl:text>
            <xsl:call-template name="x:report-test-attribute" />
            <xsl:text>,&#x0A;</xsl:text>
            <xsl:call-template name="x:call-report-sequence">
               <xsl:with-param name="sequence-variable-eqname"
                  select="'local:test-result'" />
            </xsl:call-template>
            <xsl:text>)&#x0A;</xsl:text>
            <xsl:text>else&#x0A;</xsl:text>
         </xsl:if>
         <!-- Last "else" is empty. If there is no data type mismatch and no x:expect/@test,
            there is nothing else to record here. -->
         <xsl:text>()&#x0A;</xsl:text>
         <xsl:text>&#x0A;</xsl:text>
         <xsl:text>,&#x0A;</xsl:text>

         <xsl:call-template name="x:call-report-sequence">
            <xsl:with-param name="sequence-variable-eqname" select="x:variable-UQName(.)" />
            <xsl:with-param name="report-name" select="local-name()" />
         </xsl:call-template>

      </xsl:if>
      <xsl:text>}&#x0A;</xsl:text>

      <!-- </x:test> -->
      <xsl:text>&#x0A;</xsl:text>

      <!-- End of the function -->
      <xsl:text>};&#x0A;</xsl:text>
   </xsl:template>

</xsl:stylesheet>