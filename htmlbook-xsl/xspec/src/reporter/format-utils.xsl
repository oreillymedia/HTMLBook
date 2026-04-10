<?xml version="1.0" encoding="UTF-8"?>
<!-- ===================================================================== -->
<!--  File:       format-utils.xsl                                         -->
<!--  Author:     Jeni Tennison                                            -->
<!--  Tags:                                                                -->
<!--    Copyright (c) 2008, 2010 Jeni Tennison (see end of file.)          -->
<!-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -->


<xsl:stylesheet version="3.0"
                xmlns="http://www.w3.org/1999/xhtml"
                xmlns:deq="urn:x-xspec:common:deep-equal"
                xmlns:fmt="urn:x-xspec:reporter:format-utils"
                xmlns:pkg="http://expath.org/ns/pkg"
                xmlns:x="http://www.jenitennison.com/xslt/xspec"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                exclude-result-prefixes="#all">

   <pkg:import-uri>http://www.jenitennison.com/xslt/xspec/format-utils.xsl</pkg:import-uri>

   <!--
      Use $report-theme to select a color palette CSS file in this directory:
      * test-report-colors-blackwhite.css  (black text on white background)
      * test-report-colors-whiteblack.css  (white text on black background)
      * test-report-colors-classic.css     (green for successes, pink for failures)
      
      The $report-theme value is expected to be the part of the filename
      between 'test-report-colors-' and '.css'.
   -->
   <xsl:param name="report-theme" as="xs:string" select="'default'" />
   <xsl:variable name="report-theme-to-use" as="xs:string"
      select="if ($report-theme ne 'default') then $report-theme else 'blackwhite'"/>

   <!-- @character specifies intermediate characters for mimicking @disable-output-escaping.
      For the test result report HTML, these Private Use Area characters should be considered
      as reserved by fmt:disable-escaping. -->
   <xsl:character-map name="fmt:disable-escaping">
      <xsl:output-character character="&#xE801;" string="&lt;" />
      <xsl:output-character character="&#xE802;" string="&amp;" />
      <xsl:output-character character="&#xE803;" string="&gt;" />
      <xsl:output-character character="&#xE804;" string="&apos;" />
      <xsl:output-character character="&#xE805;" string="&quot;" />
   </xsl:character-map>

   <!--
      mode="fmt:serialize"
      All the whitespace-only text nodes except the ones in <x:ws> are considered to be of indentation.
   -->
   <xsl:mode name="fmt:serialize" on-multiple-match="fail" on-no-match="fail" />

   <xsl:template match="element()" as="node()+" mode="fmt:serialize">
      <xsl:param name="level" as="xs:integer" select="0" tunnel="yes" />
      <xsl:param name="perform-comparison" as="xs:boolean" select="false()" tunnel="yes" />
      <xsl:param name="node-to-compare-with" as="node()?" />
      <xsl:param name="expected" as="xs:boolean" select="true()" />

      <!-- Open the start tag of this element -->
      <xsl:text>&lt;</xsl:text>

      <!-- Output the name of this element -->
      <xsl:choose>
         <xsl:when test="$perform-comparison">
            <span class="{fmt:comparison-html-class(., $node-to-compare-with, $expected, true())}">
               <xsl:value-of select="name()" />
            </span>
         </xsl:when>
         <xsl:otherwise>
            <xsl:value-of select="name()" />
         </xsl:otherwise>
      </xsl:choose>

      <!-- Whitespace string for indenting namespace or attribute -->
      <xsl:variable name="ns-attr-indent" as="xs:string">
         <xsl:value-of>
            <xsl:text>&#xA;</xsl:text>
            <xsl:for-each select="1 to $level">
               <xsl:text>   </xsl:text>
            </xsl:for-each>
            <xsl:value-of
               select="
                  ('&lt;' || name())
                  => replace('.', ' ')" />
         </xsl:value-of>
      </xsl:variable>

      <!-- Namespace nodes -->
      <xsl:variable name="namespaces" as="namespace-node()*" select="x:copy-of-namespaces(.)" />
      <xsl:variable name="parent-namespaces" as="namespace-node()*"
         select="parent::element() => x:copy-of-namespaces()" />
      <xsl:variable name="new-namespaces" as="namespace-node()*">
         <xsl:choose>
            <xsl:when test="$level eq 0">
               <!-- Take all -->
               <xsl:sequence select="$namespaces" />
            </xsl:when>

            <xsl:otherwise>
               <!-- Take only the ones not appeared in the parent -->
               <xsl:sequence select="for $ns in $namespaces
                  return $ns
                     [empty(
                        $parent-namespaces
                        [name() eq name($ns) (: prefix :)]
                        [string() eq string($ns) (: URI :)]
                     )]" />
            </xsl:otherwise>
         </xsl:choose>
      </xsl:variable>

      <!-- Output xmlns="" to undeclare the default namespace -->
      <xsl:if
         test="
            ($level ge 1)
            and exists($parent-namespaces[name() = ''])
            and empty($namespaces[name() = ''])">
         <xsl:text> </xsl:text>
         <span class="xmlns">xmlns=""</span>
      </xsl:if>

      <!-- Output namespace nodes -->
      <xsl:for-each select="$new-namespaces">
         <!-- Sort in namespace prefix -->
         <xsl:sort select="name()" />

         <xsl:if test="position() ge 2">
            <xsl:value-of select="$ns-attr-indent" />
         </xsl:if>
         <xsl:text> </xsl:text>
         <span
            class="{
               'xmlns',
               'trivial'[current() = ($x:xs-namespace, $x:xspec-namespace)]
            }">
            <xsl:text expand-text="yes">xmlns{name()[.] ! (':' || .)}="{.}"</xsl:text>
         </span>
      </xsl:for-each>

      <!-- Output attributes while performing comparison -->
      <xsl:for-each select="attribute()">
         <xsl:variable name="attribute-to-compare-with" as="attribute()?"
            select="(
            $node-to-compare-with/attribute()[node-name(.) eq node-name(current())],
            $node-to-compare-with/@x:attrs[string(.) = '...']
            )[1]" />

         <!-- Attribute value adjusted for display -->
         <xsl:variable name="display-value" as="xs:string"
            select="
               .
               => replace('&quot;', '&amp;quot;', 'q')
               => replace('\s(\s+)', '&#x0A;$1')" />
         <xsl:variable name="display-value-in-quot" as="xs:string"
            select="'&quot;' || $display-value || '&quot;'" />

         <xsl:if test="$new-namespaces or (position() ge 2)">
            <xsl:value-of select="$ns-attr-indent" />
         </xsl:if>
         <xsl:text> </xsl:text>
         <xsl:choose>
            <xsl:when test="$perform-comparison">
               <span class="{fmt:comparison-html-class(., $attribute-to-compare-with, $expected, true())}">
                  <xsl:value-of select="name()" />
               </span>
            </xsl:when>
            <xsl:otherwise>
               <xsl:value-of select="name()" />
            </xsl:otherwise>
         </xsl:choose>
         <xsl:text>=</xsl:text>
         <xsl:choose>
            <xsl:when test="$perform-comparison">
               <span class="{fmt:comparison-html-class(., $attribute-to-compare-with, $expected, false())}">
                  <xsl:value-of select="$display-value-in-quot" />
               </span>
            </xsl:when>
            <xsl:otherwise>
               <xsl:value-of select="$display-value-in-quot" />
            </xsl:otherwise>
         </xsl:choose>
      </xsl:for-each>

      <!-- Handle the child nodes or end this element -->
      <xsl:choose>
         <xsl:when test="child::node()">
            <!-- Close the start tag of this element -->
            <xsl:text>&gt;</xsl:text>

            <xsl:choose>
               <!-- If this element is in Actual Result and the corresponding node in Expected Result
                  has one and only child node which is a text node of '...', then Expected Result does
                  not care about the child nodes. So just output the same ellipsis. -->
               <xsl:when test="$perform-comparison and
                  not($expected) and
                  $node-to-compare-with/node() instance of text() and
                  $node-to-compare-with = '...'">
                  <span class="same ellipsis">...</span>
               </xsl:when>

               <!-- Serialize the child nodes while performing comparison -->
               <xsl:when test="$perform-comparison">
                  <xsl:for-each select="node()">
                     <xsl:variable name="significant-pos" as="xs:integer?" select="fmt:significant-position(.)" />
                     <xsl:apply-templates select="." mode="#current">
                        <xsl:with-param name="level" select="$level + 1" tunnel="yes" />
                        <xsl:with-param name="node-to-compare-with" select="$node-to-compare-with/node()[fmt:significant-position(.) eq $significant-pos]" />
                        <xsl:with-param name="expected" select="$expected" />
                     </xsl:apply-templates>
                  </xsl:for-each>
               </xsl:when>

               <!-- Serialize the child nodes without performing comparison -->
               <xsl:otherwise>
                  <xsl:apply-templates mode="#current">
                     <xsl:with-param name="level" select="$level + 1" tunnel="yes" />
                  </xsl:apply-templates>
               </xsl:otherwise>
            </xsl:choose>

            <!-- End this element -->
            <xsl:text expand-text="yes">&lt;/{name()}&gt;</xsl:text>
         </xsl:when>

         <!-- End this element without any child node -->
         <xsl:otherwise> /&gt;</xsl:otherwise>
      </xsl:choose>
   </xsl:template>

   <xsl:template match="processing-instruction()" as="node()+" mode="fmt:serialize">
      <xsl:param name="perform-comparison" as="xs:boolean" select="false()" tunnel="yes" />
      <xsl:param name="node-to-compare-with" as="node()?" />
      <xsl:param name="expected" as="xs:boolean" select="true()" />

      <xsl:text>&lt;?</xsl:text>

      <xsl:choose>
         <xsl:when test="$perform-comparison">
            <span class="{fmt:comparison-html-class(., $node-to-compare-with, $expected, true())}">
               <xsl:value-of select="name()" />
            </span>
         </xsl:when>
         <xsl:otherwise>
            <xsl:value-of select="name()" />
         </xsl:otherwise>
      </xsl:choose>

      <xsl:text> </xsl:text>

      <xsl:choose>
         <xsl:when test="$perform-comparison">
            <span class="{fmt:comparison-html-class(., $node-to-compare-with, $expected, false())}">
               <xsl:value-of select="." />
            </span>
         </xsl:when>
         <xsl:otherwise>
            <xsl:value-of select="." />
         </xsl:otherwise>
      </xsl:choose>

      <xsl:text>?></xsl:text>
   </xsl:template>

   <xsl:template match="comment() | text() | x:ws" as="node()" mode="fmt:serialize">
      <xsl:param name="perform-comparison" as="xs:boolean" select="false()" tunnel="yes" />
      <xsl:param name="node-to-compare-with" as="node()?" />
      <xsl:param name="expected" as="xs:boolean" select="true()" />

      <xsl:variable name="serialized" as="text()">
         <xsl:choose>
            <xsl:when test="self::comment()">
               <xsl:value-of select="'&lt;!--' || . || '-->'" />
            </xsl:when>

            <xsl:when test="self::text()">
               <!-- Use serialize() to escape special characters -->
               <xsl:value-of select="serialize(., map {})" />
            </xsl:when>

            <xsl:when test="self::x:ws">
               <xsl:value-of>
                  <xsl:analyze-string select="." regex="[&#x09;&#x0A;&#x0D;&#x20;]">
                     <xsl:matching-substring>
                        <xsl:choose>
                           <xsl:when test=". eq '&#x09;'">\t</xsl:when>
                           <xsl:when test=". eq '&#x0A;'">\n</xsl:when>
                           <xsl:when test=". eq '&#x0D;'">\r</xsl:when>
                           <xsl:when test=". eq '&#x20;'">
                              <!-- OPEN BOX character -->
                              <xsl:value-of select="'&#x2423;'" />
                           </xsl:when>
                           <xsl:otherwise>
                              <xsl:message select="'ERROR: Unexpected whitespace'" terminate="yes" />
                           </xsl:otherwise>
                        </xsl:choose>
                     </xsl:matching-substring>

                     <xsl:non-matching-substring>
                        <xsl:message select="'ERROR: Unexpected character'" terminate="yes" />
                     </xsl:non-matching-substring>
                  </xsl:analyze-string>
               </xsl:value-of>
            </xsl:when>

            <xsl:otherwise>
               <xsl:message select="'ERROR: Node not serialized'" terminate="yes" />
            </xsl:otherwise>
         </xsl:choose>
      </xsl:variable>

      <xsl:choose>
         <xsl:when test="$perform-comparison or self::x:ws">
            <span class="{
                  fmt:comparison-html-class(., $node-to-compare-with, $expected, false())[$perform-comparison],
                  'whitespace'[current()/self::x:ws]
               }">
               <xsl:sequence select="$serialized" />
            </span>
         </xsl:when>

         <xsl:otherwise>
            <xsl:sequence select="$serialized" />
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>

   <xsl:template match="text()[not(normalize-space())]" as="text()?" mode="fmt:serialize">
      <xsl:param name="level" as="xs:integer" select="0" tunnel="yes" />
      <xsl:param name="indentation" as="xs:integer" select="0" tunnel="yes" />

      <xsl:choose>
         <xsl:when test="
            ($level eq 0)
            and
            (
               (: leading or trailing indent :)
               not(preceding-sibling::node()) or not(following-sibling::node())
            )">
            <!-- Discard -->
         </xsl:when>

         <xsl:when test="preceding-sibling::node()[1]/self::x:ws
            or following-sibling::node()[1]/self::x:ws">
            <!-- Indentation created after or before whitespace-only text nodes. Discard. -->
         </xsl:when>

         <xsl:otherwise>
            <xsl:text expand-text="yes">&#x0A;{substring(., $indentation + 2)}</xsl:text>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>

   <!-- Returns the position of the node, ignoring the preceding-sibling whitespace-only text nodes.
      Returns an empty sequence, if the node is a whitespace-only text node. -->
   <xsl:function name="fmt:significant-position" as="xs:integer?">
      <xsl:param name="node" as="node()" />

      <xsl:choose>
         <xsl:when test="$node/self::text() and not(normalize-space($node))">
            <!-- The node is a whitespace-only text node. Return an empty sequence. -->
         </xsl:when>

         <xsl:otherwise>
            <!-- Count the preceding-sibling nodes, ignoring whitespace-only text nodes -->
            <xsl:sequence select="
               count(
                  $node/preceding-sibling::node()
                  [not(
                     self::text() and not(normalize-space())
                  )]
               )
               + 1" />
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>

   <!-- Compares $node with $node-to-compare-with and returns an HTML class accordingly: 'same', 'inner-diff' or 'diff'
      Set $expected to true if $node is in Expected Result. Set false if in Actual Result.
      Set $focusing-on-name to true only when building an HTML class of the name of $node. -->
   <xsl:function name="fmt:comparison-html-class" as="xs:string">
      <xsl:param name="node" as="node()" />
      <xsl:param name="node-to-compare-with" as="node()?" />
      <xsl:param name="expected" as="xs:boolean" />
      <xsl:param name="focusing-on-name" as="xs:boolean" />

      <xsl:variable name="equal" as="xs:boolean" select="
         if ($expected)
         then deq:deep-equal($node, $node-to-compare-with, 'w')
         else deq:deep-equal($node-to-compare-with, $node, 'w')" />

      <xsl:choose>
         <xsl:when test="$equal or $node-to-compare-with instance of attribute(x:attrs)">
            <xsl:sequence select="'same'"/>
         </xsl:when>

         <xsl:when test="
            $focusing-on-name
            and (
               (
                  ($node[not(self::x:ws)] instance of element())
                  and ($node-to-compare-with[not(self::x:ws)] instance of element())
               )
               or (
                  ($node instance of attribute())
                  and ($node-to-compare-with instance of attribute())
               )
               or (
                  ($node instance of processing-instruction())
                  and ($node-to-compare-with instance of processing-instruction())
               )
            )
            and (node-name($node) eq node-name($node-to-compare-with))">
            <xsl:sequence select="'inner-diff'" />
         </xsl:when>

         <xsl:when test="
            not($focusing-on-name)
            and ($node instance of processing-instruction())
            and ($node-to-compare-with instance of processing-instruction())">
            <xsl:variable name="text" as="text()">
               <xsl:value-of select="$node" />
            </xsl:variable>
            <xsl:variable name="text-to-compare-with" as="text()">
               <xsl:value-of select="$node-to-compare-with" />
            </xsl:variable>
            <xsl:sequence select="fmt:comparison-html-class($text, $text-to-compare-with, $expected, $focusing-on-name)" />
         </xsl:when>

         <xsl:otherwise>
            <xsl:sequence select="'diff'"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>

   <!-- Generates <style> or <link> for CSS.
      If you enable $inline, you must use fmt:disable-escaping character map in serialization. -->
   <xsl:template name="fmt:load-css" as="element()+">
      <xsl:context-item use="absent" />

      <xsl:param name="inline" as="xs:boolean" required="yes" />
      <xsl:param name="uri" as="xs:string*" required="yes" />

      <xsl:variable as="xs:string+" name="uri-or-default" select="
            if (empty($uri)) then
            (resolve-uri(concat('test-report-colors-', $report-theme-to-use, '.css')), resolve-uri('test-report-base.css'))
            else
               $uri" />

      <xsl:choose>
         <xsl:when test="$inline">
            <style type="text/css">
               <xsl:for-each select="$uri-or-default">
                  <xsl:variable name="css-string" as="xs:string" select="unparsed-text(.)" />
   
                  <!-- Replace CR LF with LF -->
                  <xsl:variable name="css-string" as="xs:string" select="replace($css-string, '&#x0D;(&#x0A;)', '$1')" />
   
                  <xsl:text>&#xA;</xsl:text>
                  <xsl:value-of select="fmt:disable-escaping($css-string)" />
               </xsl:for-each>
            </style>
         </xsl:when>

         <xsl:otherwise>
            <xsl:for-each select="$uri-or-default">
               <link rel="stylesheet" type="text/css" href="{.}"/>   
            </xsl:for-each>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>

   <!-- Replaces < & > ' " characters with the reserved characters.
      The serializer will convert those reserved characters back to < & > ' " characters,
      provided that fmt:disable-escaping character map is specified as a serialization parameter. -->
   <xsl:function name="fmt:disable-escaping" as="xs:string">
      <xsl:param name="input" as="xs:string" />

      <xsl:sequence select="
         document('')
         /element()/xsl:character-map[@name eq 'fmt:disable-escaping']
         /translate(
            $input,
            string-join(xsl:output-character/@string),
            string-join(xsl:output-character/@character)
         )"/>
   </xsl:function>

   <!--
      Returns a semi-formatted string of URI
   -->
   <xsl:function as="xs:string" name="fmt:format-uri">
      <xsl:param as="xs:string" name="uri" />

      <xsl:choose>
         <xsl:when test="starts-with($uri, 'file:')">
            <!-- Remove 'file:' -->
            <xsl:variable as="xs:string" name="formatted" select="substring($uri, 6)" />

            <!-- Remove implicit localhost (Consolidate '///' to '/') -->
            <xsl:variable as="xs:string" name="formatted"
               select="replace($formatted, '^//(/)', '$1')" />

            <!-- Remove '/' from '/C:' -->
            <xsl:variable as="xs:string" name="formatted"
               select="replace($formatted, '^/([A-Za-z]:)', '$1')" />

            <!-- Unescape whitespace -->
            <xsl:sequence select="replace($formatted, '%20', ' ', 'q')" />
         </xsl:when>

         <xsl:otherwise>
            <xsl:sequence select="$uri" />
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>

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
