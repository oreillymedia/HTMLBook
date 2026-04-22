<?xml version="1.0" encoding="UTF-8"?>
<!-- ===================================================================== -->
<!--  File:       format-xspec-report.xsl                                  -->
<!--  Author:     Jeni Tennison                                            -->
<!--  Tags:                                                                -->
<!--    Copyright (c) 2008, 2010 Jeni Tennison (see end of file.)          -->
<!-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -->


<xsl:stylesheet version="3.0"
                xmlns="http://www.w3.org/1999/xhtml"
                xmlns:fmt="urn:x-xspec:reporter:format-utils"
                xmlns:pkg="http://expath.org/ns/pkg"
                xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                xmlns:x="http://www.jenitennison.com/xslt/xspec"
                xmlns:xhtml="http://www.w3.org/1999/xhtml"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                exclude-result-prefixes="#all">

   <xsl:include href="../common/common-utils.xsl" />
   <xsl:include href="../common/deep-equal.xsl" />
   <xsl:include href="../common/namespace-vars.xsl" />
   <xsl:include href="../common/parse-report.xsl" />
   <xsl:include href="../common/trim.xsl" />
   <xsl:include href="../common/version-utils.xsl" />
   <xsl:include href="../common/wrap.xsl" />
   <xsl:include href="format-utils.xsl" />

   <pkg:import-uri>http://www.jenitennison.com/xslt/xspec/format-xspec-report.xsl</pkg:import-uri>

   <xsl:param name="force-focus" as="xs:string?" />
   <xsl:param name="inline-css" as="xs:string" select="false() cast as xs:string" />
   <xsl:param name="report-css-uri" as="xs:string?" />
   <!-- See also report-theme parameter, which is defined in format-utils.xsl -->

   <!-- @use-character-maps for inline CSS -->
   <xsl:output method="xhtml" use-character-maps="fmt:disable-escaping" />

   <!-- Returns formatted output created from @pending -->
   <xsl:function name="x:pending-callback" as="node()*">
      <xsl:param name="pending-attribute" as="attribute(pending)?"/>

      <xsl:for-each select="normalize-space($pending-attribute)[.]">
         <xsl:text>(</xsl:text>
         <strong>
            <xsl:value-of select="." />
         </strong>
         <xsl:text>) </xsl:text>
      </xsl:for-each>
   </xsl:function>

   <!-- Returns formatted output for separator between scenarios -->
   <xsl:function name="x:separator-callback" as="text()">
      <xsl:text> </xsl:text>
   </xsl:function>

   <!-- Named template to be overridden.
      Override this template to insert additional nodes at the end of /html/head. -->
   <xsl:template name="x:html-head-callback" as="empty-sequence()">
      <xsl:context-item as="element(x:report)" use="required" />
   </xsl:template>

   <xsl:template name="x:format-top-level-scenario" as="element(xhtml:div)">
      <xsl:context-item as="element(x:scenario)" use="required" />

      <div id="top_{@id}">
         <h2>
            <xsl:call-template name="x:scenario-html-class-attribute" />
            <xsl:sequence select="x:pending-callback(@pending)"/>
            <xsl:apply-templates select="x:label" mode="x:html-report" />
            <span class="scenario-totals">
               <xsl:call-template name="x:output-test-stats">
                  <xsl:with-param name="tests" select="x:descendant-tests(.)" />
                  <xsl:with-param name="insert-labels" select="true()" />
               </xsl:call-template>
            </span>
         </h2>
         <table class="xspec" id="table_{@id}">
            <colgroup>
               <col style="width:75%" />
               <col style="width:25%" />
            </colgroup>
            <tbody>
               <tr>
                  <xsl:call-template name="x:scenario-html-class-attribute" />
                  <th>
                     <xsl:sequence select="x:pending-callback(@pending)"/>
                     <xsl:apply-templates select="x:label" mode="x:html-report" />
                  </th>
                  <th>
                     <xsl:call-template name="x:output-test-stats">
                        <xsl:with-param name="tests" select="x:descendant-tests(.)" />
                        <xsl:with-param name="insert-labels" select="true()" />
                     </xsl:call-template>
                  </th>
               </tr>
               <xsl:apply-templates select="x:test" mode="x:html-summary" />
               <xsl:for-each select=".//x:scenario[x:test]">
                  <xsl:variable name="label" as="node()+">
                     <xsl:for-each select="ancestor-or-self::x:scenario[position() != last()]">
                        <xsl:apply-templates select="x:label" mode="x:html-report" />
                        <xsl:if test="position() != last()">
                           <xsl:sequence select="x:separator-callback()"/>
                        </xsl:if>
                     </xsl:for-each>
                  </xsl:variable>
                  <tr>
                     <xsl:call-template name="x:scenario-html-class-attribute" />
                     <th>
                        <xsl:call-template name="x:report-elapsed" />
                        <xsl:sequence select="x:pending-callback(@pending)"/>
                        <xsl:choose>
                           <xsl:when test="x:test[x:is-failed-test(.)]">
                              <a href="#{@id}">
                                 <xsl:sequence select="$label" />
                              </a>
                           </xsl:when>
                           <xsl:otherwise>
                              <xsl:sequence select="$label" />
                           </xsl:otherwise>
                        </xsl:choose>
                     </th>
                     <th>
                        <xsl:call-template name="x:output-test-stats">
                           <xsl:with-param name="tests" select="x:test" />
                           <xsl:with-param name="insert-labels" select="true()" />
                        </xsl:call-template>
                     </th>
                  </tr>
                  <xsl:apply-templates select="x:test" mode="x:html-summary" />
               </xsl:for-each>
            </tbody>
         </table>
         <xsl:apply-templates select="descendant-or-self::x:scenario[x:test[x:is-failed-test(.)]]" mode="x:html-report" />
      </div>
   </xsl:template>

   <!--
      mode="#default"
   -->
   <xsl:mode on-multiple-match="fail" on-no-match="fail" />

   <xsl:template match="document-node(element(x:report))" as="element(xhtml:html)">
      <!-- Process nothing here, otherwise it's hard to override the whole processing of this stylesheet -->
      <xsl:apply-templates />
   </xsl:template>

   <xsl:template match="x:report" as="element(xhtml:html)">
      <xsl:message>
         <xsl:call-template name="x:output-test-stats">
            <xsl:with-param name="tests" select="x:descendant-tests(.)" />
            <xsl:with-param name="insert-labels" select="true()" />
         </xsl:call-template>
      </xsl:message>

      <html>
         <head>
            <title>
               <xsl:text expand-text="yes">Test Report for {(@schematron, @stylesheet, @query, @xproc)[1] => fmt:format-uri()} (</xsl:text>
               <xsl:call-template name="x:output-test-stats">
                  <xsl:with-param name="tests" select="x:descendant-tests(.)"/>
                  <xsl:with-param name="insert-labels" select="true()" />
               </xsl:call-template>
               <xsl:text>)</xsl:text>
            </title>
            <xsl:call-template name="fmt:load-css">
               <xsl:with-param name="inline" select="$inline-css cast as xs:boolean" />
               <xsl:with-param name="uri" select="$report-css-uri" />
            </xsl:call-template>
            <xsl:call-template name="x:html-head-callback"/>
         </head>
         <body id="testReport">
            <h1>Test Report</h1>
            <xsl:apply-templates select="." mode="x:html-report"/>
         </body>
      </html>
   </xsl:template>

   <!-- Returns true if the top level x:scenario needs to be processed by x:format-top-level-scenario template -->
   <xsl:function name="x:top-level-scenario-needs-format" as="xs:boolean">
      <xsl:param name="scenario-elem" as="element(x:scenario)" />

      <xsl:sequence select="$scenario-elem ! (empty(@pending) or exists(x:descendant-tests(.)))" />
   </xsl:function>

   <!--
      mode="x:html-summary"
   -->
   <xsl:mode name="x:html-summary" on-multiple-match="fail" on-no-match="fail" />

   <xsl:template match="x:test[x:is-pending-test(.)]" as="element(xhtml:tr)" mode="x:html-summary">
      <tr class="pending">
         <td>
            <xsl:sequence select="x:pending-callback(@pending)"/>
            <xsl:apply-templates select="x:label" mode="x:html-report" />
         </td>
         <td>Pending</td>
      </tr>
   </xsl:template>

   <xsl:template match="x:test[x:is-passed-test(.)]" as="element(xhtml:tr)" mode="x:html-summary">
      <tr class="successful">
         <td><xsl:apply-templates select="x:label" mode="x:html-report" /></td>
         <td>Success</td>
      </tr>
   </xsl:template>

   <xsl:template match="x:test[x:is-failed-test(.)]" as="element(xhtml:tr)" mode="x:html-summary">
      <tr class="failed">
         <td>
            <a href="#{@id}">
               <xsl:apply-templates select="x:label" mode="x:html-report" />
            </a>
         </td>
         <td>Failure</td>
      </tr>
   </xsl:template>

   <!--
      mode="x:html-report"
   -->
   <xsl:mode name="x:html-report" on-multiple-match="fail" on-no-match="fail" />

   <xsl:variable name="label" as="map(xs:string, xs:string)" select="
         map {
            'query'      : 'Query: ',
            'query-at'   : 'Query-at: ',
            'schematron' : 'Schematron: ',
            'xproc'      : 'XProc: ',
            'stylesheet' : 'Stylesheet: '
         }"/>

   <xsl:template match="x:report" as="element()+" mode="x:html-report">
      <div class="byline">
         <xsl:text expand-text="yes">Generated by XSpec v{$x:xspec-version}</xsl:text>
      </div>

      <!-- Write URIs, ignoring @stylesheet when actual test target is Schematron -->
      <xsl:for-each select="@query, @query-at, @schematron, @xproc,
         @stylesheet[current()/@schematron => empty()]">
         <p>
            <xsl:variable as="xs:string" name="attr-name" select="local-name()" />

            <xsl:value-of select="$label($attr-name)"/>

            <!-- @query is a namespace. The others are URI of file -->
            <xsl:choose>
               <xsl:when test="self::attribute(query)">
                  <xsl:value-of select="." />
               </xsl:when>

               <xsl:otherwise>
                  <a href="{.}">
                     <xsl:value-of select="fmt:format-uri(.)" />
                  </a>
               </xsl:otherwise>
            </xsl:choose>
         </p>
      </xsl:for-each>

      <p>
         <xsl:text>XSpec: </xsl:text>
         <a href="{@xspec}">
            <xsl:value-of select="fmt:format-uri(@xspec)"/>
         </a>
      </p>
      <p>
         <xsl:text expand-text="yes">Tested: {format-dateTime(@date, '[D] [MNn] [Y] at [H01]:[m01]')}</xsl:text>
      </p>
      <xsl:where-populated>
         <p>
            <xsl:call-template name="x:report-elapsed" />
         </p>
      </xsl:where-populated>
      <h2>Contents</h2>
      <table class="xspec">
         <colgroup>
            <col style="width:75%" />
            <col style="width:6.25%" />
            <col style="width:6.25%" />
            <col style="width:6.25%" />
            <col style="width:6.25%" />
         </colgroup>
         <thead>
            <tr>
               <th/>
               <xsl:for-each select="x:descendant-tests(.) => x:test-stats()">
                  <th class="totals{if (@label eq 'failed') then ' emphasis' else ''}">
                     <xsl:text expand-text="yes">{@label}:&#xA0;{@count}</xsl:text>
                  </th>
               </xsl:for-each>
            </tr>
         </thead>
         <tbody>
            <xsl:for-each select="x:scenario">
               <tr>
                  <xsl:call-template name="x:scenario-html-class-attribute">
                     <xsl:with-param name="look-for-descendant-failed-tests" select="true()" />
                  </xsl:call-template>
                  <th>
                     <xsl:call-template name="x:report-elapsed" />
                     <xsl:sequence select="x:pending-callback(@pending)"/>
                     <a>
                        <xsl:if test="x:top-level-scenario-needs-format(.)">
                           <xsl:attribute name="href" select="'#top_' || @id" />
                        </xsl:if>
                        <xsl:apply-templates select="x:label" mode="#current" />
                     </a>
                  </th>
                  <xsl:for-each select="x:descendant-tests(.) => x:test-stats()">
                     <th class="totals">
                        <xsl:value-of select="@count" />
                     </th>
                  </xsl:for-each>
               </tr>
            </xsl:for-each>
         </tbody>
      </table>
      <xsl:for-each select="x:scenario[x:top-level-scenario-needs-format(.)]">
         <xsl:call-template name="x:format-top-level-scenario"/>
      </xsl:for-each>
   </xsl:template>

   <xsl:template match="x:scenario" as="element(xhtml:div)" mode="x:html-report">
      <div id="{@id}">
         <h3>
            <xsl:for-each select="ancestor-or-self::x:scenario">
               <xsl:apply-templates select="x:label" mode="#current" />
               <xsl:if test="position() != last()">
                  <xsl:sequence select="x:separator-callback()"/>
               </xsl:if>
            </xsl:for-each>
         </h3>
         <xsl:apply-templates select="x:test[x:is-failed-test(.)]" mode="#current" />
      </div>
   </xsl:template>

   <xsl:template match="x:test" as="element(xhtml:div)" mode="x:html-report">
      <div id="{@id}" class="xTestReport">

         <xsl:variable name="result" as="element(x:result)"
            select="(x:result, x:port-specific/x:result, parent::x:scenario/x:result)[1]" />

         <h4 class="xTestReportTitle">
            <xsl:apply-templates select="x:label" mode="#current" />
         </h4>

         <div class="xTestReportHint">
            <a href="https://github.com/xspec/xspec/wiki/Understanding-Test-Results" target="_blank"
               title="What does this report mean?">[?]</a>
         </div>

         <xsl:variable as="xs:boolean" name="boolean-test" select="x:is-boolean-test(.)" />
         <xsl:variable as="xs:boolean" name="result-type-mismatch" select="x:is-result-type-mismatch(.)" />

         <table class="xspecResult">
            <thead>
               <tr>
                  <th>Result</th>
                  <th>
                     <xsl:choose>
                        <xsl:when test="$boolean-test or $result-type-mismatch">Expecting</xsl:when>
                        <xsl:otherwise>Expected Result</xsl:otherwise>
                     </xsl:choose>
                  </th>
               </tr>
            </thead>
            <tbody>
               <tr>
                  <!-- Actual Result -->
                  <td>
                     <xsl:apply-templates select="$result" mode="x:format-result">
                        <xsl:with-param name="result-to-compare-with" select="x:expect[not($boolean-test)]" />
                     </xsl:apply-templates>
                  </td>

                  <td>
                     <xsl:choose>
                        <!-- Boolean expectation -->
                        <xsl:when test="$boolean-test">
                           <pre>
                              <xsl:value-of select="x:test-attr(.)" />
                           </pre>
                        </xsl:when>

                        <!-- Data type mismatch -->
                        <xsl:when test="$result-type-mismatch">
                           <pre>
                              <xsl:value-of select="x:result-type-attr(.)" />
                           </pre>
                        </xsl:when>

                        <!-- Expected Result -->
                        <xsl:otherwise>
                           <xsl:apply-templates select="x:expect" mode="x:format-result">
                              <xsl:with-param name="result-to-compare-with" select="$result" />
                           </xsl:apply-templates>
                        </xsl:otherwise>
                     </xsl:choose>
                  </td>
               </tr>
            </tbody>
         </table>

      </div>
   </xsl:template>

   <xsl:template match="x:label" as="text()" mode="x:html-report">
      <!-- TODO: Consider doing more whitespace normalization or normalizing
         at an earlier stage (the compiler or the XML report) -->
      <xsl:value-of select="x:right-trim(.)" />
   </xsl:template>

   <!--
      mode="x:format-result"
      Formats the Actual Result or the Expected Result in HTML
   -->
   <xsl:mode name="x:format-result" on-multiple-match="fail" on-no-match="fail" />

   <xsl:template match="x:expect | x:result" as="element()+" mode="x:format-result">
      <xsl:param name="result-to-compare-with" as="element()?" required="yes" />

      <!-- True if this element represents Expected Result -->
      <xsl:variable name="expected" as="xs:boolean" select=". instance of element(x:expect)" />

      <!-- Dereference @href if any and redefine the variable with it -->
      <xsl:variable name="result-to-compare-with" as="element()?"
         select="
            if ($result-to-compare-with/@href)
            then exactly-one(document($result-to-compare-with/@href)/element())
            else $result-to-compare-with" />

      <xsl:choose>
         <xsl:when test="@href or node() or (@select eq '/self::document-node()')">
            <xsl:if test="@select">
               <p>
                  <xsl:text>XPath </xsl:text>
                  <code>
                     <xsl:if test="exists($result-to-compare-with)">
                        <xsl:attribute name="class" select="
                           fmt:comparison-html-class(
                              @select,
                              $result-to-compare-with/@select,
                              $expected,
                              false())" />
                     </xsl:if>
                     <xsl:value-of select="@select" />
                  </code>
                  <xsl:text> from:</xsl:text>
               </p>
            </xsl:if>

            <xsl:choose>
               <xsl:when test="@href">
                  <p>
                     <a href="{@href}">
                        <xsl:value-of select="fmt:format-uri(@href)" />
                     </a>
                  </p>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:variable name="indentation" as="xs:integer"
                     select="
                        x:reported-content(.)/text()[1]
                        => substring-after('&#xA;')
                        => string-length()" />
                  <pre>
                     <xsl:if test="
                           /x:report/@schematron
                           and not($expected)
                           and empty($result-to-compare-with)
                           and (@select eq '/element()')
                           and (count(x:reported-content(.)/element()) eq 1)
                           and x:reported-content(.)/svrl:schematron-output">
                        <!-- Schematron result SVRL -->
                        <xsl:attribute name="class" select="'svrl'" />
                     </xsl:if>

                     <xsl:choose>
                        <!-- Serialize the result while performing comparison -->
                        <xsl:when test="exists($result-to-compare-with)">
                           <xsl:variable name="nodes-to-compare-with" as="node()*"
                              select="x:reported-content($result-to-compare-with)/node()" />
                           <xsl:for-each select="x:reported-content(.)/node()">
                              <xsl:variable name="significant-pos" as="xs:integer?" select="fmt:significant-position(.)" />
                              <xsl:apply-templates select="." mode="fmt:serialize">
                                 <xsl:with-param name="indentation" select="$indentation" tunnel="yes" />
                                 <xsl:with-param name="perform-comparison" select="true()" tunnel="yes" />
                                 <xsl:with-param name="node-to-compare-with" select="$nodes-to-compare-with[fmt:significant-position(.) eq $significant-pos]" />
                                 <xsl:with-param name="expected" select="$expected" />
                              </xsl:apply-templates>
                           </xsl:for-each>
                        </xsl:when>

                        <!-- Serialize the result without performing comparison -->
                        <xsl:otherwise>
                           <xsl:apply-templates select="x:reported-content(.)/node()" mode="fmt:serialize">
                              <xsl:with-param name="indentation" select="$indentation" tunnel="yes" />
                           </xsl:apply-templates>
                        </xsl:otherwise>
                     </xsl:choose>
                  </pre>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:when>
         <xsl:otherwise>
            <pre>
               <xsl:value-of select="@select" />
            </pre>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>

   <xsl:template name="x:output-test-stats" as="text()?">
      <xsl:context-item use="absent" />

      <xsl:param name="tests" as="element(x:test)*" required="yes" />
      <xsl:param name="insert-labels" as="xs:boolean" select="false()" />

      <xsl:variable name="full-stats" as="element(stat)+" select="x:test-stats($tests)" />

      <!-- If $tests is empty, take only 'total' stat. (Its count is zero.) -->
      <xsl:variable name="compressed-stats" as="element(stat)+"
         select="$full-stats[exists($tests) or (@label eq 'total')]"/>

      <xsl:variable name="components" as="xs:string+">
         <xsl:for-each select="$compressed-stats">
            <xsl:sequence select="(@label[$insert-labels], @count) => string-join(': ')" />
         </xsl:for-each>
      </xsl:variable>
      <xsl:value-of select="$components" separator="{if ($insert-labels) then ' / ' else '/'}" />
   </xsl:template>

   <xsl:template name="x:report-elapsed" as="element(xhtml:span)?">
      <!-- Context item is x:report or x:scenario -->
      <xsl:context-item as="element()" use="required" />

      <xsl:if test="x:timestamp">
         <xsl:variable name="elapsed" as="xs:dayTimeDuration" select="
               xs:dateTimeStamp(x:timestamp[@event eq 'end']/@at)
               - xs:dateTimeStamp(x:timestamp[@event eq 'start']/@at)" />
         <span class="elapsed">
            <xsl:if test="self::x:scenario">(</xsl:if>
            <xsl:text>Elapsed: </xsl:text>
            <span class="elapsed-num">
               <xsl:value-of select="($elapsed div xs:dayTimeDuration('PT1S')) * 1000" />
            </span>
            <xsl:text> ms</xsl:text>
            <xsl:if test="self::x:scenario">
               <xsl:text>) </xsl:text>
            </xsl:if>
         </span>
      </xsl:if>
   </xsl:template>

   <xsl:function name="x:test-stats" as="element(stat)+">
      <xsl:param name="tests" as="element(x:test)*" />

      <xsl:variable name="passed-tests" as="element(x:test)*" select="$tests[x:is-passed-test(.)]" />
      <xsl:variable name="pending-tests" as="element(x:test)*" select="$tests[x:is-pending-test(.)]" />
      <xsl:variable name="failed-tests" as="element(x:test)*" select="$tests[x:is-failed-test(.)]" />

      <xsl:sequence xmlns="">
         <stat label="passed" count="{count($passed-tests)}" />
         <stat label="pending" count="{count($pending-tests)}" />
         <stat label="failed" count="{count($failed-tests)}" />
         <stat label="total" count="{count($tests)}" />
      </xsl:sequence>
   </xsl:function>

   <!-- Creates an HTML @class for x:scenario: 'pending', 'failed' or 'successful' -->
   <xsl:template name="x:scenario-html-class-attribute" as="attribute(class)">
      <xsl:context-item as="element(x:scenario)" use="required" />

      <xsl:param name="look-for-descendant-failed-tests" as="xs:boolean" select="false()" />

      <xsl:variable name="failed-tests" as="element(x:test)*" select="
            if ($look-for-descendant-failed-tests) then
               x:descendant-failed-tests(.)
            else
               x:test[x:is-failed-test(.)]" />

      <xsl:attribute name="class">
         <xsl:choose>
            <xsl:when test="exists(@pending)">
               <xsl:sequence select="'pending'" />
            </xsl:when>
            <xsl:when test="exists($failed-tests)">
               <xsl:sequence select="'failed'" />
            </xsl:when>
            <xsl:otherwise>
               <xsl:sequence select="'successful'" />
            </xsl:otherwise>
         </xsl:choose>
      </xsl:attribute>
   </xsl:template>

</xsl:stylesheet>


<!-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -->
<!-- DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS COMMENT.             -->
<!--                                                                       -->
<!-- Copyright (c) 2008, 2010 Jeni Tennison                                -->
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
