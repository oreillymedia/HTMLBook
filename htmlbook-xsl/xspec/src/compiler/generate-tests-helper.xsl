<?xml version="1.0" encoding="UTF-8"?>
<!-- ===================================================================== -->
<!--  File:       generate-tests-helper.xsl                                -->
<!--  Author:     Jeni Tennsion                                            -->
<!--  URI:        http://xspec.googlecode.com/                             -->
<!--  Tags:                                                                -->
<!--    Copyright (c) 2008, 2010 Jeni Tennsion (see end of file.)          -->
<!-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -->


<xsl:stylesheet version="2.0" 
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:xhtml="http://www.w3.org/1999/xhtml"
                xmlns:test="http://www.jenitennison.com/xslt/unit-test"
                extension-element-prefixes="test"
                xmlns="http://www.w3.org/1999/XSL/TransformAlias"
                xmlns:t="http://www.jenitennison.com/xslt/unit-testAlias"
                exclude-result-prefixes="#default t xhtml"
                xmlns:pkg="http://expath.org/ns/pkg"
                xmlns:__x="http://www.w3.org/1999/XSL/TransformAliasAlias">
  
<pkg:import-uri>http://www.jenitennison.com/xslt/xspec/generate-tests-helper.xsl</pkg:import-uri>

<xsl:namespace-alias stylesheet-prefix="#default" result-prefix="xsl"/>
<xsl:namespace-alias stylesheet-prefix="t" result-prefix="test"/>
  
<xsl:output indent="yes" encoding="ISO-8859-1" />  
  
<xsl:key name="functions" 
         match="xsl:function" 
         use="resolve-QName(@name, .)" />

<xsl:key name="named-templates" 
         match="xsl:template[@name]"
         use="if (contains(@name, ':'))
	            then resolve-QName(@name, .)
	            else QName('', @name)" />

<xsl:key name="matching-templates" 
         match="xsl:template[@match]" 
         use="concat('match=', normalize-space(@match), '+',
                     'mode=', normalize-space(@mode))" />


<xsl:template match="*" mode="test:generate-variable-declarations">
  <xsl:param name="var" as="xs:string" required="yes" />
  <xsl:param name="type" as="xs:string" select="'variable'" />
  <xsl:choose>
    <xsl:when test="node() or @href">
      <variable name="{$var}-doc" as="document-node()">
        <xsl:choose>
          <xsl:when test="@href">
            <xsl:attribute name="select">
              <xsl:text>doc('</xsl:text>
              <xsl:value-of select="resolve-uri(@href, base-uri(.))" />
              <xsl:text>')</xsl:text>
            </xsl:attribute>
          </xsl:when>
          <xsl:otherwise>
            <document>
              <xsl:apply-templates mode="test:create-xslt-generator" />
            </document>
          </xsl:otherwise>
        </xsl:choose>
      </variable>
      <xsl:element name="xsl:{$type}">
        <xsl:copy-of select="@as"/>
        <xsl:attribute name="name" select="$var" />
        <xsl:attribute name="select"
          select="if (@select) 
                    then concat('$', $var, '-doc/(', @select, ')')
                  else if (@href)
                    then concat('$', $var, '-doc')
                  else concat('$', $var, '-doc/node()')" />
      </xsl:element>
    </xsl:when>
    <xsl:when test="@select">
      <xsl:element name="xsl:{$type}">
        <xsl:copy-of select="@as|@select"/>
        <xsl:attribute name="name" select="$var" />
      </xsl:element>
    </xsl:when>
    <xsl:otherwise>
      <xsl:element name="xsl:{$type}">
        <xsl:copy-of select="@as"/>
        <xsl:attribute name="name" select="$var" />
        <xsl:attribute name="select" select="'()'" />
      </xsl:element>
    </xsl:otherwise>
  </xsl:choose>        
</xsl:template>  
  

<xsl:template match="*" mode="test:create-xslt-generator">
   <xsl:copy>
      <xsl:apply-templates select="@*|node()" mode="test:create-xslt-generator"/>
   </xsl:copy>
</xsl:template>  

<xsl:template match="@*" mode="test:create-xslt-generator">
   <xsl:copy-of select="."/>
</xsl:template>
  
<xsl:template match="xsl:*" mode="test:create-xslt-generator">
  <xsl:element name="__x:{ local-name() }">
    <xsl:apply-templates select="@*|node()" mode="test:create-xslt-generator"/>
  </xsl:element>
</xsl:template>  

<xsl:template match="@xsl:*" mode="test:create-xslt-generator">
   <xsl:attribute name="__x:{ local-name() }" select="."/>
</xsl:template>

<xsl:template match="text()" mode="test:create-xslt-generator">
  <text>
     <xsl:value-of select="."/>
  </text>
</xsl:template>  

<xsl:template match="comment()" mode="test:create-xslt-generator">
  <comment>
     <xsl:value-of select="."/>
  </comment>
</xsl:template>

<xsl:template match="processing-instruction()" mode="test:create-xslt-generator">
  <processing-instruction name="{name()}">
    <xsl:value-of select="."/>
  </processing-instruction>
</xsl:template>

<xsl:function name="test:matching-xslt-elements" as="element()*">
  <xsl:param name="element-kind" as="xs:string"/>
  <xsl:param name="element-id" as="item()"/>
  <xsl:param name="stylesheet" as="document-node()"/>
  <xsl:sequence select="key($element-kind, $element-id, $stylesheet)"/>
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
