<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.w3.org/1999/XSL/TransformAlias"
                xmlns:wrap="urn:x-xspec:common:wrap"
                xmlns:x="http://www.jenitennison.com/xslt/xspec"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                exclude-result-prefixes="#all"
                version="3.0">

   <!--
      Generate an XSLT template from the expect element.
      
      This generated template, when called, checks the expectation against the actual result of the
      test and constructs the corresponding x:test element for the XML report.
   -->
   <xsl:template name="x:compile-expect" as="element(xsl:template)">
      <xsl:context-item as="element(x:expect)" use="required" />

      <xsl:param name="reason-for-pending" as="xs:string?" required="yes" />

      <!-- URIQualifiedNames of the (required) parameters of the template being generated -->
      <xsl:param name="param-uqnames" as="xs:string*" required="yes" />

      <xsl:element name="xsl:template" namespace="{$x:xsl-namespace}">
         <xsl:attribute name="name" select="x:known-UQName('x:' || @id)" />
         <xsl:attribute name="as" select="'element(' || x:known-UQName('x:test') || ')'" />

         <xsl:element name="xsl:context-item" namespace="{$x:xsl-namespace}">
            <xsl:attribute name="use" select="'absent'" />
         </xsl:element>

         <xsl:for-each select="$param-uqnames">
            <param name="{.}" as="item()*" required="yes" />
         </xsl:for-each>

         <xsl:apply-templates select="." mode="scope-result-variable"
            use-when="$test-type eq 'xproc'">
            <xsl:with-param name="reason-for-pending" select="$reason-for-pending"/>
         </xsl:apply-templates>

         <message>
            <xsl:if test="exists($reason-for-pending)">
               <xsl:text>PENDING: </xsl:text>
               <xsl:for-each select="normalize-space($reason-for-pending)[.]">
                  <xsl:text expand-text="yes">({.}) </xsl:text>
               </xsl:for-each>
            </xsl:if>
            <xsl:value-of select="x:label(.) => normalize-space()" />
         </message>

         <xsl:if test="empty($reason-for-pending)">
            <xsl:variable name="xslt-version" as="xs:decimal" select="x:xslt-version(.)" />

            <!-- Set up the $impl:expected variable -->
            <xsl:apply-templates select="." mode="x:declare-variable">
               <xsl:with-param name="comment" select="'expected result'" />
            </xsl:apply-templates>

            <!-- Flags for deq:deep-equal() -->
            <xsl:variable name="deep-equal-flags" as="xs:string"
               select="x:deep-equal-flags(., $xslt-version)" />

            <xsl:comment> flag if @result-type is present but $x:result is not the right type </xsl:comment>
            <variable name="{x:known-UQName('impl:result-type-mismatch')}"
               as="{x:known-UQName('xs:boolean')}"
               select="{x:result-type-mismatch-condition(.)}"/>

            <xsl:choose>
               <xsl:when test="@test">
                  <xsl:call-template name="define-impl-test-items"/>

                  <xsl:comment> evaluate the predicate with $x:result (or its wrapper document node) as context item if it is a single item; if not, evaluate the predicate without context item </xsl:comment>
                  <variable name="{x:known-UQName('impl:test-result')}" as="item()*">
                     <choose>
                        <when test="${x:known-UQName('impl:result-type-mismatch')}">
                           <xsl:comment>In case of data type mismatch, do not process @test</xsl:comment>
                        </when>
                        <when test="count(${x:known-UQName('impl:test-items')}) eq 1">
                           <for-each select="${x:known-UQName('impl:test-items')}">
                              <xsl:element name="xsl:sequence" namespace="{$x:xsl-namespace}">
                                 <!-- @test may use namespace prefixes and/or the default namespace
                                    such as xs:QName('foo') -->
                                 <xsl:sequence select="x:copy-of-namespaces(.)" />

                                 <xsl:attribute name="select" select="@test" />
                                 <xsl:attribute name="version" select="$xslt-version" />
                              </xsl:element>
                           </for-each>
                        </when>
                        <otherwise>
                           <xsl:element name="xsl:sequence" namespace="{$x:xsl-namespace}">
                              <!-- @test may use namespace prefixes and/or the default namespace
                                 such as xs:QName('foo') -->
                              <xsl:sequence select="x:copy-of-namespaces(.)" />

                              <xsl:attribute name="select" select="@test" />
                              <xsl:attribute name="version" select="$xslt-version" />
                           </xsl:element>
                        </otherwise>
                     </choose>
                  </variable>

                  <!-- TODO: Remove duality from @test. (expath/xspec#5) -->
                  <variable name="{x:known-UQName('impl:boolean-test')}" as="{x:known-UQName('xs:boolean')}"
                     select="${x:known-UQName('impl:test-result')} instance of {x:known-UQName('xs:boolean')}" />

                  <xsl:comment> did the test pass? </xsl:comment>
                  <variable name="{x:known-UQName('impl:successful')}" as="{x:known-UQName('xs:boolean')}">
                     <choose>
                        <when test="${x:known-UQName('impl:result-type-mismatch')}">
                           <sequence select="false()"/>
                        </when>
                        <when test="${x:known-UQName('impl:boolean-test')}">
                           <xsl:choose>
                              <xsl:when test="x:has-comparison(.)">
                                 <message terminate="yes">
                                    <xsl:text expand-text="yes">{x:boolean-with-comparison(.)}</xsl:text>
                                 </message>
                              </xsl:when>
                              <xsl:otherwise>
                                 <!-- Without boolean(), Saxon warning SXWN9000 (xspec/xspec#46).
                                    "cast as" does not work (xspec/xspec#153). -->
                                 <sequence select="${x:known-UQName('impl:test-result')} => boolean()" />
                              </xsl:otherwise>
                           </xsl:choose>
                        </when>
                        <otherwise>
                           <xsl:choose>
                              <xsl:when test="x:has-comparison(.)">
                                 <sequence select="{x:known-UQName('deq:deep-equal')}(${x:variable-UQName(.)}, ${x:known-UQName('impl:test-result')}, {$deep-equal-flags})" />
                              </xsl:when>
                              <xsl:otherwise>
                                 <message terminate="yes">
                                    <xsl:text expand-text="yes">{x:non-boolean-without-comparison(.)}</xsl:text>
                                 </message>
                              </xsl:otherwise>
                           </xsl:choose>
                        </otherwise>
                     </choose>
                  </variable>
               </xsl:when>

               <xsl:otherwise>
                  <variable name="{x:known-UQName('impl:successful')}" as="{x:known-UQName('xs:boolean')}"
                     select="not(${x:known-UQName('impl:result-type-mismatch')}) and
                     {x:known-UQName('deq:deep-equal')}(${x:variable-UQName(.)}, ${x:known-UQName('x:result')}, {$deep-equal-flags})" />
               </xsl:otherwise>
            </xsl:choose>

            <if test="not(${x:known-UQName('impl:successful')})">
               <message>
                  <xsl:text>      FAILED</xsl:text>
               </message>
            </if>
         </xsl:if>

         <!-- <x:test> -->
         <xsl:element name="xsl:element" namespace="{$x:xsl-namespace}">
            <xsl:attribute name="name" select="'test'" />
            <xsl:attribute name="namespace" select="namespace-uri()" />

            <xsl:variable name="test-element-attributes" as="attribute()+">
               <xsl:sequence select="@id" />
               <xsl:sequence select="x:pending-attribute-from-reason($reason-for-pending)" />
            </xsl:variable>
            <xsl:apply-templates select="$test-element-attributes" mode="x:node-constructor" />

            <xsl:if test="empty($reason-for-pending)">
               <!-- @successful must be evaluated at run time -->
               <xsl:element name="xsl:attribute" namespace="{$x:xsl-namespace}">
                  <xsl:attribute name="name" select="'successful'" />
                  <xsl:attribute name="namespace" />
                  <xsl:attribute name="select" select="'$' || x:known-UQName('impl:successful')" />
               </xsl:element>
            </xsl:if>

            <xsl:apply-templates select="x:label(.)" mode="x:node-constructor" />

            <!-- Report -->
            <xsl:if test="empty($reason-for-pending)">
               <!-- Record data the report will need, based on outcomes fully known only at run time. -->
               <choose>
                  <when test="${x:known-UQName('impl:result-type-mismatch')}">
                     <!-- For failure due to data type mismatch, record the "instance of" expression. -->
                     <xsl:call-template name="x:report-test-attribute">
                        <xsl:with-param name="attribute-local-name" select="'result-type'"/>
                     </xsl:call-template>
                     <xsl:call-template name="x:record-port-specific-result"
                        use-when="$test-type eq 'xproc'"/>
                  </when>
                  <xsl:if test="exists(@test)">
                     <when test="${x:known-UQName('impl:boolean-test')}">
                        <!-- For failure due to boolean x:expect/@test, record @test. -->
                        <xsl:call-template name="x:report-test-attribute" />
                        <xsl:call-template name="x:record-port-specific-result"
                           use-when="$test-type eq 'xproc'"/>
                     </when>
                     <when test="not(${x:known-UQName('impl:boolean-test')})">
                        <!-- For failure due to non-boolean x:expect/@test, record @test and the result
                        of evaluating @test against $x:result. -->
                        <xsl:call-template name="x:report-test-attribute" />
                        <xsl:call-template name="x:call-report-sequence">
                           <xsl:with-param name="sequence-variable-eqname"
                              select="x:known-UQName('impl:test-result')" />
                        </xsl:call-template>
                     </when>
                  </xsl:if>
                  <otherwise>
                     <xsl:call-template name="x:record-port-specific-result"
                        use-when="$test-type eq 'xproc'"/>
                     <!-- If there's no port-specific result, no data type mismatch, and no
                        x:expect/@test, there is nothing else to record here and the 'otherwise'
                        branch is empty. -->
                  </otherwise>
               </choose>
               <!-- For all x:expect syntaxes/outcomes, record the expected result in the result XML file -->
               <xsl:call-template name="x:call-report-sequence">
                  <xsl:with-param name="sequence-variable-eqname" select="x:variable-UQName(.)" />
                  <xsl:with-param name="report-name" select="local-name()" />
               </xsl:call-template>
            </xsl:if>

         <!-- </x:test> -->
         </xsl:element>
      </xsl:element>
   </xsl:template>

</xsl:stylesheet>