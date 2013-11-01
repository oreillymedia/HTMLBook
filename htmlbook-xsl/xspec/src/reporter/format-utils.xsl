<?xml version="1.0" encoding="UTF-8"?>
<!-- ===================================================================== -->
<!--  File:       format-utils.xsl                                         -->
<!--  Author:     Jeni Tennsion                                            -->
<!--  URI:        http://xspec.googlecode.com/                             -->
<!--  Tags:                                                                -->
<!--    Copyright (c) 2008, 2010 Jeni Tennsion (see end of file.)          -->
<!-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -->


<xsl:stylesheet version="2.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:test="http://www.jenitennison.com/xslt/unit-test"
                xmlns:x="http://www.jenitennison.com/xslt/xspec"
                xmlns="http://www.w3.org/1999/xhtml"
                xmlns:pkg="http://expath.org/ns/pkg"
                exclude-result-prefixes="test xs">

<xsl:import href="../compiler/generate-tests-utils.xsl" />

<pkg:import-uri>http://www.jenitennison.com/xslt/xspec/format-utils.xsl</pkg:import-uri>

<xsl:output name="x:report" method="xml" indent="yes"/>

<xsl:variable name="omit-namespaces" as="xs:string+"
  select="('http://www.w3.org/XML/1998/namespace',
           'http://www.w3.org/1999/XSL/Transform',
           'http://www.w3.org/2001/XMLSchema',
           'http://www.jenitennison.com/xslt/unit-test',
           'http://www.jenitennison.com/xslt/xspec')" />

<xsl:template match="*" mode="test:serialize" priority="20">
  <xsl:param name="level" as="xs:integer" select="0" tunnel="yes" />
  <xsl:param name="perform-comparison" tunnel="yes" as="xs:boolean" select="false()" />
  <xsl:param name="comparison" as="node()?" select="()" />
  <xsl:param name="expected" as="xs:boolean" select="true()" />
  <xsl:text>&lt;</xsl:text>
  <xsl:choose>
    <xsl:when test="$perform-comparison">
      <span class="{if (if ($expected) then test:deep-equal(., $comparison) else test:deep-equal($comparison, .)) then 'same' else 'diff'}">
        <xsl:value-of select="name()" />
      </span>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="name()" />
    </xsl:otherwise>
  </xsl:choose>
  <xsl:variable name="attribute-indent" as="xs:string">
    <xsl:value-of>
      <xsl:text>&#xA;</xsl:text>
      <xsl:for-each select="1 to $level"><xsl:text>   </xsl:text></xsl:for-each>
      <xsl:value-of select="replace(name(parent::*), '.', ' ')" />
    </xsl:value-of>
  </xsl:variable>
  <xsl:variable name="new-namespaces" as="node()*" 
    select="namespace::*[not(. = $omit-namespaces) and ($level = 0 or not(name() = ../../namespace::*/name()))]" />
  <xsl:if test="not(namespace::*[name() = '']) and ../namespace::*[name() = '']">
    <xsl:text> xmlns=""</xsl:text>
  </xsl:if>
  <xsl:for-each select="$new-namespaces">
    <xsl:if test="position() > 1">
      <xsl:value-of select="$attribute-indent" />
    </xsl:if>
    <xsl:text> xmlns</xsl:text>
    <xsl:if test="name()">
      <xsl:value-of select="concat(':', name())" />
    </xsl:if>
    <xsl:text>="</xsl:text>
    <xsl:value-of select="." />
    <xsl:text>"</xsl:text>
  </xsl:for-each>
  <xsl:for-each select="@*">
    <xsl:if test="$new-namespaces or position() > 1">
      <xsl:value-of select="$attribute-indent" />
    </xsl:if>
    <xsl:text> </xsl:text>
    <xsl:choose>
      <xsl:when test="$perform-comparison">
        <xsl:variable name="name" as="xs:QName" select="node-name(.)" />
        <xsl:variable name="comparison-att" as="attribute()?" select="$comparison/@*[node-name(.) = $name]" />
        <span class="{if (if ($expected) then test:deep-equal(., $comparison-att) else test:deep-equal($comparison-att, .)) then 'same' else 'diff'}">
          <xsl:value-of select="name()" />
        </span>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="name()" />
      </xsl:otherwise>
    </xsl:choose>
    <xsl:text>="</xsl:text>
    <xsl:value-of select="replace(replace(., '&quot;', '&amp;quot;'),
      '\s(\s+)', '&#xA;$1')" />
    <xsl:text>"</xsl:text>
  </xsl:for-each>
  <xsl:choose>
    <xsl:when test="child::node()">
      <xsl:text>&gt;</xsl:text>
      <xsl:choose>
        <xsl:when test="$perform-comparison and
          not($expected) and
          $comparison/node() instance of text() and
          $comparison = '...'">
          <xsl:text>...</xsl:text>
        </xsl:when>
        <xsl:when test="$perform-comparison">
          <xsl:for-each select="node()">
            <xsl:variable name="pos" as="xs:integer" select="position()" />
            <xsl:apply-templates select="." mode="test:serialize">
              <xsl:with-param name="level" select="$level + 1" tunnel="yes" />
              <xsl:with-param name="comparison" select="$comparison/node()[position() = $pos]" />
              <xsl:with-param name="expected" select="$expected" />
            </xsl:apply-templates>
          </xsl:for-each>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates mode="test:serialize">
            <xsl:with-param name="level" select="$level + 1" tunnel="yes" />
          </xsl:apply-templates>
        </xsl:otherwise>
      </xsl:choose>      
      <xsl:text>&lt;/</xsl:text>
      <xsl:value-of select="name()" />
      <xsl:text>&gt;</xsl:text>
    </xsl:when>
    <xsl:otherwise> /&gt;</xsl:otherwise>
  </xsl:choose>
</xsl:template>  

<xsl:template match="comment()" mode="test:serialize">
  <xsl:sequence
    select="concat('&lt;--', ., '--&gt;')" />
</xsl:template>  

<xsl:template match="processing-instruction()" mode="test:serialize">
  <xsl:sequence select="concat('&lt;?', name(), ' ', ., '?&gt;')" />
</xsl:template>  

<xsl:template match="node()" mode="test:serialize" priority="10">
  <xsl:param name="perform-comparison" tunnel="yes" as="xs:boolean" select="false()" />
  <xsl:param name="comparison" as="node()?" select="()" />
  <xsl:param name="expected" as="xs:boolean" select="true()" />
  <xsl:variable name="serialized" as="item()*">
    <xsl:next-match />
  </xsl:variable>
  <xsl:choose>
    <xsl:when test="$perform-comparison">
      <span class="{if (if ($expected) then test:deep-equal(., $comparison) else test:deep-equal($comparison, .)) then 'same' else 'diff'}">
        <xsl:copy-of select="$serialized" />
      </span>
    </xsl:when>
    <xsl:otherwise>
      <xsl:copy-of select="$serialized" />
    </xsl:otherwise>
  </xsl:choose>	
</xsl:template>

<xsl:template match="test:ws" mode="test:serialize" priority="30">
  <xsl:param name="perform-comparison" as="xs:boolean" tunnel="yes" select="false()" />
  <xsl:if test="$perform-comparison">
    <span class="whitespace">
      <xsl:analyze-string select="." regex="\s">
        <xsl:matching-substring>
          <xsl:choose>
            <xsl:when test=". = '&#xA;'">\n</xsl:when>
            <xsl:when test=". = '&#xD;'">\r</xsl:when>
            <xsl:when test=". = '&#x9;'">\t</xsl:when>
            <xsl:when test=". = ' '">.</xsl:when>
          </xsl:choose>
        </xsl:matching-substring>
      </xsl:analyze-string>
    </span>
  </xsl:if>
</xsl:template>

<xsl:template match="text()[not(normalize-space())]" mode="test:serialize" priority="20">
  <xsl:param name="indentation" as="xs:integer" tunnel="yes" select="0" />
  <xsl:value-of select="concat('&#xA;', substring(., $indentation + 2))" />
</xsl:template>  

<xsl:function name="test:format-URI" as="xs:string">
  <xsl:param name="URI" as="xs:anyURI" />
  <xsl:choose>
    <xsl:when test="starts-with($URI, 'file:/')">
      <xsl:value-of select="replace(substring-after($URI, 'file:/'), '%20', ' ')" />
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="$URI" />
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
