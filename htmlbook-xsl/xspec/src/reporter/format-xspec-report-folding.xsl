<?xml version="1.0" encoding="UTF-8"?>
<!-- ===================================================================== -->
<!--  File:       format-xspec-report-folding.xsl                          -->
<!--  Author:     Jeni Tennison                                            -->
<!--  Tags:                                                                -->
<!--    Copyright (c) 2008, 2010 Jeni Tennison (see end of file.)          -->
<!-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -->


<xsl:stylesheet version="3.0"
                xmlns="http://www.w3.org/1999/xhtml"
                xmlns:pkg="http://expath.org/ns/pkg"
                xmlns:x="http://www.jenitennison.com/xslt/xspec"
                xmlns:xhtml="http://www.w3.org/1999/xhtml"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                exclude-result-prefixes="#all">

   <!-- Import the non-folding reporter and override it -->
   <xsl:import href="format-xspec-report.xsl" />

   <pkg:import-uri>http://www.jenitennison.com/xslt/xspec/format-xspec-report-folding.xsl</pkg:import-uri>

   <xsl:template name="x:html-head-callback" as="element(xhtml:script)">
      <xsl:context-item use="absent" />

      <script language="javascript" type="text/javascript">
function toggle(scenarioID) {
   table = document.getElementById("table_"+scenarioID);
   icon = document.getElementById("icon_"+scenarioID)
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
      icon.src = "<xsl:value-of select="resolve-uri('../../graphics/3angle-down.gif')"/>" ;
      icon.alt = "collapse" ;
      icon.title = "collapse" ;
   }
   else {
      table.style.display = "none";
      icon.src = "<xsl:value-of select="resolve-uri('../../graphics/3angle-right.gif')"/>" ;
      icon.alt = "expand" ;
      icon.title = "expand" ;
   };

   return;
}
</script>
   </xsl:template>

   <xsl:template name="x:format-top-level-scenario" as="element(xhtml:div)">
      <xsl:context-item as="element(x:scenario)" use="required" />

      <xsl:variable name="any-descendant-failure" as="xs:boolean"
         select="x:descendant-failed-tests(.) => exists()" />

      <div id="top_{@id}">
         <h2>
            <xsl:call-template name="x:scenario-html-class-attribute" />
            <a href="javascript:toggle('{@id}')">
               <xsl:variable name="graphics-dir" as="xs:anyURI" select="resolve-uri('../../graphics/')" />
               <xsl:variable name="img-file" as="xs:string"
                  select="if ($any-descendant-failure) then '3angle-down.gif' else '3angle-right.gif'" />
               <img src="{resolve-uri($img-file, $graphics-dir)}"
                  alt="{if ($any-descendant-failure) then 'collapse' else 'expand'}"
                  id="icon_{@id}" />
            </a>
            <xsl:sequence select="x:pending-callback(@pending)"/>
            <xsl:apply-templates select="x:label" mode="x:html-report" />
            <span class="scenario-totals">
               <xsl:call-template name="x:output-test-stats">
                  <xsl:with-param name="tests" select="x:descendant-tests(.)" />
               </xsl:call-template>
            </span>
         </h2>
         <table class="xspec" id="table_{@id}" style="display: {if ($any-descendant-failure) then 'table' else 'none'}">
            <colgroup>
               <col style="width:85%" />
               <col style="width:15%" />
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
                  <tr id="{@id}">
                     <xsl:call-template name="x:scenario-html-class-attribute" />
                     <th>
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
