<?xml version="1.0" encoding="UTF-8"?>
<!-- ===================================================================== -->
<!--  File:       format-xspec-report.xsl                                  -->
<!--  Author:     Jeni Tennsion                                            -->
<!--  URI:        http://xspec.googlecode.com/                             -->
<!--  Tags:                                                                -->
<!--    Copyright (c) 2008, 2010 Jeni Tennsion (see end of file.)          -->
<!-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -->


<xsl:stylesheet version="2.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:x="http://www.jenitennison.com/xslt/xspec"
                xmlns:test="http://www.jenitennison.com/xslt/unit-test"
                exclude-result-prefixes="x xs test pkg"
                xmlns:pkg="http://expath.org/ns/pkg"
                xmlns="http://www.w3.org/1999/xhtml">

<xsl:import href="format-utils.xsl"/>

<pkg:import-uri>http://www.jenitennison.com/xslt/xspec/format-xspec-report.xsl</pkg:import-uri>

<xsl:param name="report-css-uri" select="
    resolve-uri('test-report.css', static-base-uri())"/>

<xsl:function name="x:pending-callback" as="node()*">
  <!-- returns formatted output for $pending. -->
  <xsl:param name="pending" as="xs:string?"/>
  <xsl:if test="$pending">
    <xsl:text>(</xsl:text>
    <strong><xsl:value-of select="$pending"/></strong>
    <xsl:text>) </xsl:text>
  </xsl:if>
</xsl:function>

<xsl:function name="x:separator-callback" as="node()*">
  <!-- returns formatted output for separator between scenarios. -->
  <xsl:text> </xsl:text>
</xsl:function>

<xsl:template name="x:html-head-callback" as="node()*"/>
  
<xsl:template name="x:format-top-level-scenario">
  <xsl:variable name="pending" as="xs:boolean"
    select="exists(@pending)" />
  <xsl:variable name="any-failure" as="xs:boolean"
    select="exists(x:test[@successful = 'false'])" />
  <div id="{generate-id()}">
    <h2 class="{if ($pending) then 'pending' else if ($any-failure) then 'failed' else 'successful'}">
      <xsl:copy-of select="x:pending-callback(@pending)"/>
      <xsl:apply-templates select="x:label" mode="x:html-report" />
      <span class="scenario-totals">
        <xsl:call-template name="x:totals">
          <xsl:with-param name="tests" select=".//x:test[parent::x:scenario]" />
        </xsl:call-template>
      </span>
    </h2>
    <table class="xspec" id="t-{generate-id()}">
      <col width="85%" />
      <col width="15%" />
      <tbody>
        <tr class="{if ($pending) then 'pending' else if ($any-failure) then 'failed' else 'successful'}">
          <th>
            <xsl:copy-of select="x:pending-callback(@pending)"/>
            <xsl:apply-templates select="x:label" mode="x:html-report" />
          </th>
          <th>
            <xsl:call-template name="x:totals">
              <xsl:with-param name="tests" select=".//x:test[parent::x:scenario]" />
            </xsl:call-template>
          </th>
        </tr>
        <xsl:apply-templates select="x:test" mode="x:html-summary" />
        <xsl:for-each select=".//x:scenario[x:test]">
          <xsl:variable name="pending" as="xs:boolean"
            select="exists(@pending)" />
          <xsl:variable name="any-failure" as="xs:boolean"
            select="exists(x:test[@successful = 'false'])" />
          <xsl:variable name="label" as="node()+">
            <xsl:for-each select="ancestor-or-self::x:scenario[position() != last()]">
              <xsl:apply-templates select="x:label" mode="x:html-report" />
              <xsl:if test="position() != last()">
                <xsl:copy-of select="x:separator-callback()"/>
              </xsl:if>
            </xsl:for-each>
          </xsl:variable>
          <tr class="{if ($pending) then 'pending' else if ($any-failure) then 'failed' else 'successful'}">
            <th>
              <xsl:copy-of select="x:pending-callback(@pending)"/>
              <xsl:choose>
                <xsl:when test="$any-failure">
                  <a href="#{generate-id()}">
                    <xsl:sequence select="$label" />
                  </a>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:sequence select="$label" />
                </xsl:otherwise>
              </xsl:choose>
            </th>
            <th>
              <xsl:call-template name="x:totals">
                <xsl:with-param name="tests" select="x:test" />
              </xsl:call-template>
            </th>
          </tr>
          <xsl:apply-templates select="x:test" mode="x:html-summary" />
        </xsl:for-each>
      </tbody>
    </table>
    <xsl:apply-templates select="descendant-or-self::x:scenario[x:test[@successful = 'false']]" mode="x:html-report" />
  </div>
</xsl:template>

<xsl:template match="/">
  <xsl:message>
    <xsl:call-template name="x:totals">
      <xsl:with-param name="tests" select="//x:scenario/x:test" />
      <xsl:with-param name="labels" select="true()" />
    </xsl:call-template>
  </xsl:message>
  <html>
    <head>
      <title>
         <xsl:text>Test Report for </xsl:text>
         <xsl:value-of select="x:report/test:format-URI(@stylesheet|@query)"/>
         <xsl:text> (</xsl:text>
         <xsl:call-template name="x:totals">
            <xsl:with-param name="tests" select="//x:scenario/x:test"/>
         </xsl:call-template>
         <xsl:text>)</xsl:text>
      </title>
      <link rel="stylesheet" type="text/css" href="{ $report-css-uri }"/>
      <xsl:call-template name="x:html-head-callback"/>
    </head>
    <body>
      <h1>Test Report</h1>
      <xsl:apply-templates select="*"/>
    </body>
  </html>
</xsl:template>

<xsl:template match="x:report">
   <xsl:apply-templates select="." mode="x:html-report"/>
</xsl:template>

<xsl:template match="x:report" mode="x:html-report">
  <p>
     <xsl:value-of select="if ( exists(@query) ) then 'Query: ' else 'Stylesheet: '"/>
     <a href="{ @stylesheet|@query }">
        <xsl:value-of select="test:format-URI(@stylesheet|@query)"/>
     </a>
  </p>
  <p>
    <xsl:text>Tested: </xsl:text>
    <xsl:value-of select="format-dateTime(@date, '[D] [MNn] [Y] at [H01]:[m01]')" />
  </p>
  <h2>Contents</h2>
  <table class="xspec">
    <col width="85%" />
    <col width="15%" />
    <thead>
      <tr>
        <th style="text-align: right; font-weight: normal; ">passed/pending/failed/total</th>
        <th>
          <xsl:call-template name="x:totals">
            <xsl:with-param name="tests" select="//x:scenario/x:test" />
          </xsl:call-template>
        </th>
      </tr>
    </thead>
    <tbody>
      <xsl:for-each select="x:scenario">
        <xsl:variable name="pending" as="xs:boolean"
          select="exists(@pending)" />
        <xsl:variable name="any-failure" as="xs:boolean"
          select="exists(.//x:test[parent::x:scenario][@successful = 'false'])" />
        <tr class="{if ($pending) then 'pending' else if ($any-failure) then 'failed' else 'successful'}">
          <th>
            <xsl:copy-of select="x:pending-callback(@pending)"/>
            <a href="#{generate-id()}">
              <xsl:apply-templates select="x:label" mode="x:html-report" />
            </a>
          </th>
          <th>
            <xsl:call-template name="x:totals">
              <xsl:with-param name="tests" select=".//x:test[parent::x:scenario]" />
            </xsl:call-template>
          </th>
        </tr>
      </xsl:for-each>
    </tbody>
  </table>
  <xsl:for-each select="x:scenario[not(@pending)]">
    <xsl:call-template name="x:format-top-level-scenario"/>
  </xsl:for-each>
</xsl:template>

<xsl:template match="x:test[exists(@pending)]" mode="x:html-summary">
  <tr class="pending">
    <td>
      <xsl:copy-of select="x:pending-callback(@pending)"/>
      <xsl:apply-templates select="x:label" mode="x:html-report" />
    </td>
    <td>Pending</td>
  </tr>
</xsl:template>

<xsl:template match="x:test[@successful = 'true']" mode="x:html-summary">
  <tr class="successful">
  	<td><xsl:apply-templates select="x:label" mode="x:html-report" /></td>
    <td>Success</td>
  </tr>
</xsl:template>

<xsl:template match="x:test[@successful = 'false']" mode="x:html-summary">
  <tr class="failed">
    <td>
      <a href="#{generate-id()}">
      	<xsl:apply-templates select="x:label" mode="x:html-report" />
      </a>
    </td>
    <td>Failure</td>
  </tr>
</xsl:template>

<xsl:template match="x:scenario" mode="x:html-report">
  <h3 id="{generate-id()}">
  	<xsl:for-each select="ancestor-or-self::x:scenario">
  		<xsl:apply-templates select="x:label" mode="x:html-report" />
  		<xsl:if test="position() != last()">
        <xsl:copy-of select="x:separator-callback()"/>
  		</xsl:if>
  	</xsl:for-each>
  </h3>
  <xsl:apply-templates select="x:test[@successful = 'false']" mode="x:html-report" />
</xsl:template>

<xsl:template match="x:test" mode="x:html-report">
  <xsl:variable name="result" as="element(x:result)"
    select="if (x:result) then x:result else ../x:result" />
  <h4 id="{generate-id()}">
    <xsl:apply-templates select="x:label" mode="x:html-report" />
  </h4>
  <table class="xspecResult">
    <thead>
      <tr>
        <th>Result</th>
        <th>
          <xsl:choose>
            <xsl:when test="x:result">Expecting</xsl:when>
            <xsl:otherwise>Expected Result</xsl:otherwise>
          </xsl:choose>
        </th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td>
          <xsl:apply-templates select="$result" mode="x:value">
            <xsl:with-param name="comparison" select="x:expect" />
          </xsl:apply-templates>
        </td>
        <td>
          <xsl:choose>
            <xsl:when test="not(x:result) and x:expect/@test">
              <pre>
                <xsl:value-of select="@test" />
              </pre>
            </xsl:when>
            <xsl:otherwise>
              <xsl:apply-templates select="x:expect" mode="x:value">
                <xsl:with-param name="comparison" select="$result" />
              </xsl:apply-templates>
            </xsl:otherwise>
          </xsl:choose>
        </td>
      </tr>
    </tbody>
  </table>
</xsl:template>

<xsl:template match="*" mode="x:value">
  <xsl:param name="comparison" as="element()?" select="()" />
  <xsl:variable name="expected" as="xs:boolean" select=". instance of element(x:expect)" />
  <xsl:choose>
    <xsl:when test="@href or node()">
      <xsl:if test="@select">
        <p>XPath <code><xsl:value-of select="@select" /></code> from:</p>
      </xsl:if>
      <xsl:choose>
        <xsl:when test="@href">
          <p><a href="{@href}"><xsl:value-of select="test:format-URI(@href)" /></a></p>
        </xsl:when>
        <xsl:otherwise>
          <xsl:variable name="indentation"
            select="string-length(substring-after(text()[1], '&#xA;'))" />
          <pre>
            <xsl:choose>
              <xsl:when test="exists($comparison)">
                <xsl:variable name="compare" as="node()*"
                  select="if ($comparison/@href)
                          then document($comparison/@href)/node()
                          else $comparison/(node() except text()[not(normalize-space())])" />
                <xsl:for-each select="node() except text()[not(normalize-space())]">
                  <xsl:variable name="pos" as="xs:integer" select="position()" />
                  <xsl:apply-templates select="." mode="test:serialize">
                    <xsl:with-param name="indentation" tunnel="yes" select="$indentation" />
                    <xsl:with-param name="perform-comparison" tunnel="yes" select="true()" />
                    <xsl:with-param name="comparison" select="$compare[position() = $pos]" />
                    <xsl:with-param name="expected" select="$expected" />
                  </xsl:apply-templates>
                </xsl:for-each>
              </xsl:when>
              <xsl:otherwise>
                <xsl:apply-templates select="node() except text()[not(normalize-space())]" mode="test:serialize">
                  <xsl:with-param name="indentation" tunnel="yes"
                    select="$indentation" />
                </xsl:apply-templates>
              </xsl:otherwise>
            </xsl:choose>
          </pre>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:when>
    <xsl:otherwise>
      <pre><xsl:value-of select="@select" /></pre>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template name="x:totals">
  <xsl:param name="tests" as="element(x:test)*" required="yes" />
  <xsl:param name="labels" as="xs:boolean" select="false()" />
  <xsl:if test="$tests">
    <xsl:variable name="passed" as="element(x:test)*" select="$tests[@successful = 'true']" />
    <xsl:variable name="pending" as="element(x:test)*" select="$tests[exists(@pending)]" />
    <xsl:variable name="failed" as="element(x:test)*" select="$tests[@successful = 'false']" />
    <xsl:if test="$labels">passed: </xsl:if>
    <xsl:value-of select="count($passed)" />
    <xsl:if test="$labels"><xsl:text> </xsl:text></xsl:if>
    <xsl:text>/</xsl:text>
    <xsl:if test="$labels"> pending: </xsl:if>
    <xsl:value-of select="count($pending)" />
    <xsl:if test="$labels"><xsl:text> </xsl:text></xsl:if>
    <xsl:text>/</xsl:text>
    <xsl:if test="$labels"> failed: </xsl:if>
    <xsl:value-of select="count($failed)" />
    <xsl:if test="$labels"><xsl:text> </xsl:text></xsl:if>
    <xsl:text>/</xsl:text>
    <xsl:if test="$labels"> total: </xsl:if>
    <xsl:value-of select="count($tests)" />
  </xsl:if>
</xsl:template>

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
