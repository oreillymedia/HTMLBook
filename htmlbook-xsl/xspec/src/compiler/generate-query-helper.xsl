<?xml version="1.0" encoding="UTF-8"?>
<!-- ===================================================================== -->
<!--  File:       generate-query-helper.xsl                                -->
<!--  Author:     Jeni Tennsion                                            -->
<!--  URI:        http://xspec.googlecode.com/                             -->
<!--  Tags:                                                                -->
<!--    Copyright (c) 2008, 2010 Jeni Tennsion (see end of file.)          -->
<!-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -->


<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:xhtml="http://www.w3.org/1999/xhtml"
                xmlns:test="http://www.jenitennison.com/xslt/unit-test"
                xmlns:pkg="http://expath.org/ns/pkg"
                extension-element-prefixes="test"
                exclude-result-prefixes="xs xhtml"
                version="2.0">
  
   <pkg:import-uri>http://www.jenitennison.com/xslt/xspec/generate-query-helper.xsl</pkg:import-uri>

   <xsl:key name="functions" 
            match="xsl:function" 
            use="resolve-QName(@name, .)"/>

   <xsl:key name="named-templates" 
            match="xsl:template[@name]"
            use="if ( contains(@name, ':') ) then
                   resolve-QName(@name, .)
                 else
                   QName('', @name)"/>

   <xsl:key name="matching-templates" 
            match="xsl:template[@match]" 
            use="concat('match=', normalize-space(@match), '+',
                        'mode=', normalize-space(@mode))"/>

   <xsl:template match="*" mode="test:generate-variable-declarations">
      <xsl:param name="var"    as="xs:string"  required="yes"/>
      <xsl:param name="global" as="xs:boolean" select="false()"/>
      <xsl:choose>
         <xsl:when test="$global">
            <xsl:text>declare variable $</xsl:text>
         </xsl:when>
         <xsl:otherwise>
            <xsl:text>  let $</xsl:text>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:value-of select="$var"/>
      <xsl:if test="@as">
         <xsl:text> as </xsl:text>
         <xsl:value-of select="@as"/>
      </xsl:if>
      <xsl:choose>
         <xsl:when test="@href">
            <xsl:text> := doc('</xsl:text>
            <xsl:value-of select="resolve-uri(@href, base-uri(.))"/>
            <xsl:text>')</xsl:text>
            <xsl:if test="@select">/( <xsl:value-of select="@select"/> )</xsl:if>
         </xsl:when>
         <xsl:when test="node()">
            <xsl:text> := ( </xsl:text>
            <xsl:for-each select="node() except text()[not(normalize-space(.))]">
               <xsl:apply-templates select="." mode="test:create-xslt-generator"/>
               <xsl:if test="position() ne last()">
                  <xsl:text>, </xsl:text>
               </xsl:if>
            </xsl:for-each>
            <xsl:text> )</xsl:text>
            <xsl:if test="@select">/( <xsl:value-of select="@select"/> )</xsl:if>
         </xsl:when>
         <xsl:when test="@select">
            <xsl:text> := ( </xsl:text>
            <xsl:value-of select="@select"/>
            <xsl:text> )</xsl:text>
         </xsl:when>
         <xsl:otherwise>
            <xsl:text> := ()</xsl:text>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:if test="$global">
         <xsl:text>;</xsl:text>
      </xsl:if>
      <xsl:text>&#10;</xsl:text>
   </xsl:template>

   <xsl:template match="*" mode="test:create-xslt-generator">
     <!--xsl:copy>
       <xsl:copy-of select="@*"/>
       <xsl:apply-templates mode="test:create-xslt-generator"/>
     </xsl:copy-->
     <xsl:copy-of select="."/>
   </xsl:template>  

   <!-- FIXME: Escape the quoted string... -->
   <xsl:template match="text()" mode="test:create-xslt-generator">
      <xsl:text>text { "</xsl:text>
      <xsl:value-of select="."/>
      <xsl:text>" }</xsl:text>
   </xsl:template>  

   <xsl:template match="comment()" mode="test:create-xslt-generator">
      <xsl:text>comment { </xsl:text>
      <xsl:value-of select="."/>
      <xsl:text> }</xsl:text>
   </xsl:template>

   <xsl:template match="processing-instruction()" mode="test:create-xslt-generator">
      <xsl:text>processing-instruction { </xsl:text>
      <xsl:value-of select="name(.)"/>
      <xsl:text> } { </xsl:text>
      <xsl:value-of select="."/>
      <xsl:text> }</xsl:text>
   </xsl:template>

   <xsl:function name="test:matching-xslt-elements" as="element()*">
     <xsl:param name="element-kind" as="xs:string" />
     <xsl:param name="element-id" as="item()" />
     <xsl:param name="stylesheet" as="document-node()" />
     <xsl:sequence select="key($element-kind, $element-id, $stylesheet)" />
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
