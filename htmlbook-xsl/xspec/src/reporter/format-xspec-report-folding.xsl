<?xml version="1.0" encoding="UTF-8"?>
<!-- ===================================================================== -->
<!--  File:       format-xspec-report-folding.xsl                          -->
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
                exclude-result-prefixes="x xs test"
                xmlns:pkg="http://expath.org/ns/pkg"
                xmlns="http://www.w3.org/1999/xhtml">

<xsl:import href="format-xspec-report.xsl" />

<pkg:import-uri>http://www.jenitennison.com/xslt/xspec/format-xspec-report-folding.xsl</pkg:import-uri>

<xsl:template name="x:html-head-callback">
  <script language="javascript" type="text/javascript">
function toggle(scenarioID) {
  table = document.getElementById("t-"+scenarioID);
  icon = document.getElementById("icon-"+scenarioID)
  // need to:
  //   switch table.style.display between 'none' and 'block'
  //   switch between collapse and expand icons

   if (table.style.display == "none") {
    // This try/catch is to handle IE 7.  It doesn't support table.style.display = "table"
    try {
      table.style.display = "table";
    } catch(err) {
      table.style.display = "block";
    }
    icon.src = "<xsl:value-of select="resolve-uri('graphics/3angle-down.gif', static-base-uri())"/>" ;
    icon.alt = "collapse" ;
    icon.title = "collapse" ;
  }
  else {
    table.style.display = "none";
    icon.src = "<xsl:value-of select="resolve-uri('graphics/3angle-right.gif', static-base-uri())"/>" ;
    icon.alt = "expand" ;
    icon.title = "expand" ;
  };

  return;
}
</script>
</xsl:template>

<xsl:template name="x:format-top-level-scenario">
  <xsl:variable name="pending" as="xs:boolean"
    select="exists(@pending)" />
  <xsl:variable name="any-failure" as="xs:boolean"
    select="exists(x:test[@successful = 'false'])" />
  <xsl:variable name="any-descendant-failure" as="xs:boolean"
    select="exists(.//x:test[@successful = 'false'])" />
  <div id="{generate-id()}">
    <h2 id="h-{generate-id()}"
      class="{if ($pending) then 'pending' else if ($any-failure) then 'failed' else 'successful'}">
      <a href="javascript:toggle('{generate-id()}')">
        <img src="{resolve-uri(concat('graphics/', if ($any-descendant-failure) then '3angle-down.gif' else '3angle-right.gif'), static-base-uri())}"
          alt="{if ($any-descendant-failure) then 'collapse' else 'expand'}" id="icon-{generate-id()}"/>
      </a>
      <xsl:copy-of select="x:pending-callback(@pending)"/>
      <xsl:apply-templates select="x:label" mode="x:html-report" />
      <span class="scenario-totals">
        <xsl:call-template name="x:totals">
          <xsl:with-param name="tests" select=".//x:test" />
        </xsl:call-template>
      </span>
    </h2>
    <table class="xspec" id="t-{generate-id()}" style="display: {if ($any-descendant-failure) then 'table' else 'none'}">
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
              <xsl:with-param name="tests" select=".//x:test" />
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
          <tr id="{generate-id()}"
            class="{if ($pending) then 'pending' else if ($any-failure) then 'failed' else 'successful'}">
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
