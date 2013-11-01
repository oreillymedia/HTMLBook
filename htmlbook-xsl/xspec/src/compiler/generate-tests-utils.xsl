<?xml version="1.0" encoding="UTF-8"?>
<!-- ===================================================================== -->
<!--  File:       generate-tests-utils.xsl                                 -->
<!--  Author:     Jeni Tennsion                                            -->
<!--  URI:        http://xspec.googlecode.com/                             -->
<!--  Tags:                                                                -->
<!--    Copyright (c) 2008, 2010 Jeni Tennsion (see end of file.)          -->
<!-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -->


<xsl:stylesheet version="2.0" 
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:msxsl="urn:schemas-microsoft-com:xslt"
                exclude-result-prefixes="xs t msxsl"
                xmlns:test="http://www.jenitennison.com/xslt/unit-test"
                xmlns:x="http://www.jenitennison.com/xslt/xspec"
                extension-element-prefixes="test"
                xmlns:pkg="http://expath.org/ns/pkg"
                xmlns:t="http://www.jenitennison.com/xslt/unit-testAlias">

<pkg:import-uri>http://www.jenitennison.com/xslt/xspec/generate-tests-utils.xsl</pkg:import-uri>

<xsl:namespace-alias stylesheet-prefix="t" result-prefix="test"/>

<!-- TODO: ... -->
<xsl:param name="debug" as="xs:boolean" select="true()"/>

<!-- Generate an human-readable path to a node within its document. -->
<xsl:function name="x:node-path" as="xs:string">
   <xsl:param name="n" as="node()"/>
   <!-- TODO: In case of a root document node, the path begins with '//'... -->
   <xsl:sequence select="string-join($n/ancestor-or-self::node()/x:node-step(.), '/')"/>
</xsl:function>

<xsl:function name="x:node-step" as="xs:string">
   <xsl:param name="n" as="node()"/>
   <xsl:choose>
      <xsl:when test="$n instance of document-node()">
         <xsl:sequence select="'/'"/>
      </xsl:when>
      <xsl:when test="$n instance of element()">
         <xsl:variable name="precedings" select="
             $n/preceding-sibling::*[name(.) eq name($n)]"/>
         <xsl:sequence select="concat(name($n), x:node-position($precedings))"/>
      </xsl:when>
      <xsl:when test="$n instance of attribute()">
         <xsl:sequence select="concat('@', name($n))"/>
      </xsl:when>
      <xsl:when test="$n instance of text()">
         <xsl:variable name="precedings" select="
             $n/preceding-sibling::text()"/>
         <xsl:sequence select="concat('text()', x:node-position($precedings))"/>
      </xsl:when>
      <xsl:when test="$n instance of comment()">
         <xsl:variable name="precedings" select="
             $n/preceding-sibling::comment()"/>
         <xsl:sequence select="concat('comment()', x:node-position($precedings))"/>
      </xsl:when>
      <xsl:when test="$n instance of processing-instruction()">
         <xsl:variable name="precedings" select="
             $n/preceding-sibling::processing-instruction[name(.) eq name($n)]"/>
         <xsl:sequence select="concat('pi(', name($n), ')', x:node-position($precedings))"/>
      </xsl:when>
      <!-- if not, that's a namespace node -->
      <xsl:otherwise>
         <xsl:sequence select="concat('ns({', name($n), '}', $n, ')')"/>
      </xsl:otherwise>
   </xsl:choose>
</xsl:function>

<xsl:function name="x:node-position" as="xs:string?">
   <xsl:param name="precedings" as="node()*"/>
   <xsl:if test="exists($precedings)">
      <xsl:sequence select="concat('[', count($precedings) + 1, ']')"/>
   </xsl:if>
</xsl:function>

<test:tests>
  <test:title>test:deep-equal function</test:title>
  <test:test>
    <test:title>Identical Sequences</test:title>
    <test:param name="seq1" select="(1, 2)" />
    <test:param name="seq2" select="(1, 2)" />
    <test:expect select="true()" />
  </test:test>
  <test:test>
    <test:title>Non-Identical Sequences</test:title>
    <test:param name="seq1" select="(1, 2)" />
    <test:param name="seq2" select="(1, 3)" />
    <test:expect select="false()" />
  </test:test>
  <test:test id="deep-equal.3">
    <test:title>Sequences with Same Items in Different Orders</test:title>
    <test:param name="seq1" select="(1, 2)" />
    <test:param name="seq2" select="(2, 1)" />
    <test:expect select="false()" />
  </test:test>
  <test:test id="deep-equal.4">
    <test:title>Empty Sequences</test:title>
    <test:param name="seq1" select="()" />
    <test:param name="seq2" select="()" />
    <test:expect select="true()" />
  </test:test>
  <test:test>
    <test:title>One empty sequence</test:title>
    <test:param name="seq1" select="()" />
    <test:param name="seq2" select="1" />
    <test:expect select="false()" />
  </test:test>
  <test:test>
    <test:title>A text node and several text nodes</test:title>
    <test:param name="seq1" select="text()">foobar</test:param>
    <test:param name="seq2" select="val/text()">
      <val>foo</val>
      <val>bar</val>
    </test:param>
    <test:expect select="true()" />
  </test:test>
</test:tests>
<xsl:function name="test:deep-equal" as="xs:boolean">
  <xsl:param name="seq1" as="item()*" />
  <xsl:param name="seq2" as="item()*" />
  <xsl:sequence select="test:deep-equal($seq1, $seq2, 2.0)" />
</xsl:function>

<xsl:function name="test:deep-equal" as="xs:boolean">
  <xsl:param name="seq1" as="item()*"/>
  <xsl:param name="seq2" as="item()*"/>
  <xsl:param name="version" as="xs:double"/>
  <!-- Using a $param in @use-when does not work.  TODO: What to do? At run time? -->
  <!--xsl:if test="$seq1 instance of node()" use-when="$debug">
     <xsl:message select="'DEEP-EQUAL: SEQ1:', x:node-path($seq1)"/>
  </xsl:if>
  <xsl:if test="$seq2 instance of node()" use-when="$debug">
     <xsl:message select="'DEEP-EQUAL: SEQ2:', x:node-path($seq2)"/>
  </xsl:if-->
  <xsl:variable name="result" as="xs:boolean">
     <xsl:choose>
        <xsl:when test="$version = 1.0">
           <xsl:choose>
              <xsl:when test="$seq1 instance of xs:string and
                              $seq2 instance of text()+">
                 <xsl:sequence select="test:deep-equal($seq1, string-join($seq2, ''))"/>
              </xsl:when>
              <xsl:when test="$seq1 instance of xs:double and
                              $seq2 instance of text()+">
                 <xsl:sequence select="test:deep-equal($seq1, xs:double(string-join($seq2, '')))"/>
              </xsl:when>
              <xsl:when test="$seq1 instance of xs:decimal and
                              $seq2 instance of text()+">
                 <xsl:sequence select="test:deep-equal($seq1, xs:decimal(string-join($seq2, '')))"/>
              </xsl:when>
              <xsl:when test="$seq1 instance of xs:integer and
                              $seq2 instance of text()+">
                 <xsl:sequence select="test:deep-equal($seq1, xs:integer(string-join($seq2, '')))"/>
              </xsl:when>
              <xsl:otherwise>
                 <xsl:sequence select="test:deep-equal($seq1, $seq2)"/>
              </xsl:otherwise>
           </xsl:choose>
        </xsl:when>
        <xsl:when test="empty($seq1) or empty($seq2)">
           <xsl:sequence select="empty($seq1) and empty($seq2)"/>
        </xsl:when>
        <xsl:when test="count($seq1) = count($seq2)">
           <xsl:sequence select="every $i in (1 to count($seq1)) 
                                 satisfies test:item-deep-equal($seq1[$i], $seq2[$i])"/>
        </xsl:when>
        <xsl:when test="$seq1 instance of text() and
                        $seq2 instance of text()+">
           <xsl:variable name="seq2" as="text()">
              <xsl:value-of select="$seq2" separator=""/>
           </xsl:variable>
           <xsl:sequence select="test:deep-equal($seq1, $seq2, $version)"/>
        </xsl:when>
        <xsl:when test="$seq1 instance of node()+ and $seq2 instance of node()+ and empty($seq1[. instance of attribute()]) and empty($seq2[. instance of attribute()])">
           <xsl:variable name="seq1a" as="document-node()">
              <xsl:document>
                 <xsl:sequence select="$seq1"/>
              </xsl:document>
           </xsl:variable>
           <xsl:variable name="seq2a" as="document-node()">
              <xsl:document>
                 <xsl:sequence select="$seq2"/>
              </xsl:document>
           </xsl:variable>
           <xsl:choose>
              <xsl:when test="count($seq1a/node()) != count($seq1) or count($seq2a/node()) != count($seq2)">
                 <xsl:sequence select="test:deep-equal($seq1a/node(), $seq2a/node(), $version)"/>
              </xsl:when>
              <xsl:otherwise>
                 <xsl:sequence select="false()"/>
              </xsl:otherwise>
           </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
           <xsl:sequence select="false()"/>
        </xsl:otherwise>
     </xsl:choose>
  </xsl:variable>
  <!-- Using a $param in @use-when does not work.  TODO: What to do? At run time? -->
  <!--xsl:message select="'DEEP-EQUAL: RESULT:', $result" use-when="$debug"/-->
  <xsl:sequence select="$result"/>
</xsl:function>

<test:tests>
  <test:title>test:item-deep-equal function</test:title>
  <test:test id="item-deep-equal.1">
    <test:title>Identical Integers</test:title>
    <test:param name="item1" select="1" />
    <test:param name="item2" select="1" />
    <test:expect select="true()" />
  </test:test>
  <test:test id="item-deep-equal.2">
    <test:title>Non-Identical Strings</test:title>
    <test:param name="item1" select="'abc'" />
    <test:param name="item2" select="'def'" />
    <test:expect select="false()" />
  </test:test>
  <test:test id="item-deep-equal.3">
    <test:title>String and Integer</test:title>
    <test:param name="item1" select="'1'" />
    <test:param name="item2" select="1" />
    <test:expect select="false()" />
  </test:test>
</test:tests>
<xsl:function name="test:item-deep-equal" as="xs:boolean">
  <xsl:param name="item1" as="item()" />
  <xsl:param name="item2" as="item()" />
  <xsl:choose>
    <xsl:when test="$item1 instance of node() and
                    $item2 instance of node()">
      <xsl:sequence select="test:node-deep-equal($item1, $item2)" />
    </xsl:when>
    <xsl:when test="not($item1 instance of node()) and
                    not($item2 instance of node())">
      <xsl:sequence select="deep-equal($item1, $item2)" />      
    </xsl:when>
    <xsl:otherwise>
      <xsl:sequence select="false()" />
    </xsl:otherwise>
  </xsl:choose>
</xsl:function>  
  
<test:tests>
  <test:title>test:node-deep-equal function</test:title>
  <test:test id="node-deep-equal.1">
    <test:title>Identical Elements</test:title>
    <test:param name="node1" select="/*">
      <result/>
    </test:param>
    <test:param name="node2" select="/*">
      <result/>
    </test:param>
    <test:expect select="true()" />
  </test:test>
  <test:test id="node-deep-equal.2">
    <test:title>Elements with Identical Attributes in Different Orders</test:title>
    <test:param name="node1" select="/*">
      <result a="1" b="2" />
    </test:param>
    <test:param name="node2" select="/*">
      <result b="2" a="1" />
    </test:param>
    <test:expect select="true()" />
  </test:test>
  <test:test id="node-deep-equal.3">
    <test:title>Elements with Identical Children</test:title>
    <test:param name="node1" select="/*">
      <result><child1/><child2/></result>
    </test:param>
    <test:param name="node2" select="/*">
      <result><child1/><child2/></result>
    </test:param>
    <test:expect select="true()" />
  </test:test>
  <test:test id="node-deep-equal.4">
    <test:title>Identical Attributes</test:title>
    <test:param name="node1" select="/*/@a">
      <result a="1" />
    </test:param>
    <test:param name="node2" select="/*/@a">
      <result a="1" />
    </test:param>
    <test:expect select="true()" />
  </test:test>
  <test:test id="node-deep-equal.5">
    <test:title>Identical Document Nodes</test:title>
    <test:param name="node1" select="/">
      <result />
    </test:param>
    <test:param name="node2" select="/">
      <result />
    </test:param>
    <test:expect select="true()" />
  </test:test>
  <test:test id="node-deep-equal.6">
    <test:title>Identical Text Nodes</test:title>
    <test:param name="node1" select="/*/text()">
      <result>Test</result>
    </test:param>
    <test:param name="node2" select="/*/text()">
      <result>Test</result>
    </test:param>
    <test:expect select="true()" />
  </test:test>
  <test:test id="node-deep-equal.7">
    <test:title>Identical Comments</test:title>
    <test:param name="node1" select="/comment()">
      <!-- Comment -->
      <doc />
    </test:param>
    <test:param name="node2" select="/comment()">
      <!-- Comment -->
      <doc />
    </test:param>
    <test:expect select="true()" />
  </test:test>
  <test:test id="node-deep-equal.8">
    <test:title>Identical Processing Instructions</test:title>
    <test:param name="node1" select="/processing-instruction()">
      <?pi data?>
      <doc />
    </test:param>
    <test:param name="node2" select="/processing-instruction()">
      <?pi data?>
      <doc />
    </test:param>
    <test:expect select="true()" />
  </test:test>
  <test:test>
    <test:title>Using "..." to indicate missing text</test:title>
    <test:param name="node1">
      <foo>...</foo>
    </test:param>
    <test:param name="node2">
      <foo>foo</foo>
    </test:param>
    <test:expect select="true()" />
  </test:test>
  <test:test>
    <test:title>Using "..." to indicate missing mixed content</test:title>
    <test:param name="node1">
      <foo>...</foo>
    </test:param>
    <test:param name="node2">
      <foo>foo<bar />foo</foo>
    </test:param>
    <test:expect select="true()" />
  </test:test>
  <test:test>
    <test:title>Using "..." to indicate missing attribute values</test:title>
    <test:param name="node1" select="/foo/@bar">
      <foo bar="..." />
    </test:param>
    <test:param name="node2" select="/foo/@bar">
      <foo bar="bar" />
    </test:param>
    <test:expect select="true()" />
  </test:test>
  <test:test>
    <test:title>Using "..." to indicate missing empty content</test:title>
    <test:param name="node1" select="/foo">
      <foo>...</foo>
    </test:param>
    <test:param name="node2" select="/foo">
      <foo />
    </test:param>
    <test:expect select="true()" />
  </test:test>
</test:tests>
<xsl:function name="test:node-deep-equal" as="xs:boolean">
  <xsl:param name="node1" as="node()" />
  <xsl:param name="node2" as="node()" />
  <xsl:choose>
    <xsl:when test="$node1 instance of document-node() and
                    $node2 instance of document-node()">
      <xsl:variable name="children1" as="node()*" 
        select="test:sorted-children($node1)" />
      <xsl:variable name="children2" as="node()*" 
        select="test:sorted-children($node2)" />
      <xsl:sequence select="test:deep-equal($children1,
                                            $children2)" />
    </xsl:when>
    <xsl:when test="$node1 instance of element() and
                    $node2 instance of element()">
      <xsl:choose>
        <xsl:when test="node-name($node1) eq node-name($node2)">
          <xsl:variable name="atts1" as="attribute()*">
            <xsl:perform-sort select="$node1/@*">
              <xsl:sort select="namespace-uri(.)" />
              <xsl:sort select="local-name(.)" />
            </xsl:perform-sort>
          </xsl:variable>
          <xsl:variable name="atts2" as="attribute()*">
            <xsl:perform-sort select="$node2/@*">
              <xsl:sort select="namespace-uri(.)" />
              <xsl:sort select="local-name(.)" />
            </xsl:perform-sort>
          </xsl:variable>
          <xsl:choose>
            <xsl:when test="test:deep-equal($atts1, $atts2)">
              <xsl:choose>
                <xsl:when test="$node1/text() = '...' and count($node1/node()) = 1">
                  <xsl:sequence select="true()" />
                </xsl:when>
                <xsl:otherwise>
                  <xsl:variable name="children1" as="node()*" 
                    select="test:sorted-children($node1)" />
                  <xsl:variable name="children2" as="node()*" 
                    select="test:sorted-children($node2)" />
                  <xsl:sequence select="test:deep-equal($children1,
                                                        $children2)" />
                </xsl:otherwise>
              </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
              <xsl:sequence select="false()" />
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="false()" />
        </xsl:otherwise>
      </xsl:choose>
    </xsl:when>
    <xsl:when test="$node1 instance of text() and
                    $node1 = '...'">
      <xsl:sequence select="true()" />
    </xsl:when>
    <xsl:when test="$node1 instance of text() and
                    $node2 instance of text()">
      <!--
      <xsl:choose>
        <xsl:when test="not(normalize-space($node1)) and 
                        not(normalize-space($node2))">
          <xsl:sequence select="true()" />
        </xsl:when>
        <xsl:otherwise>
      -->
          <xsl:sequence select="string($node1) eq string($node2)" />
        <!--
        </xsl:otherwise>
      </xsl:choose>
      -->
    </xsl:when>
    <xsl:when test="($node1 instance of attribute() and
                     $node2 instance of attribute()) or
                    ($node1 instance of processing-instruction() and
                     $node2 instance of processing-instruction())">
      <xsl:sequence select="node-name($node1) eq node-name($node2) and
                            ($node1 = '...' or string($node1) eq string($node2))" />      
    </xsl:when>
    <xsl:when test="$node1 instance of comment() and
                    $node2 instance of comment()">
      <xsl:sequence select="$node1 = '...' or string($node1) eq string($node2)" />
    </xsl:when>
    <xsl:otherwise>
      <xsl:sequence select="false()" />
    </xsl:otherwise>
  </xsl:choose>  
</xsl:function>
  
<test:tests>
  <test:title>test:sorted-children function</test:title>
  <test:test>
    <test:title>Original order preserved</test:title>
    <test:param name="node">
      <foo><bar /><baz /></foo>
    </test:param>
    <test:expect>
      <bar /><baz />
    </test:expect>
  </test:test>
</test:tests>  
<xsl:function name="test:sorted-children" as="node()*">
  <xsl:param name="node" as="node()" />
  <xsl:sequence 
    select="$node/child::node() 
            except ($node/text()[not(normalize-space(.))],
                    $node/test:message)" />
</xsl:function>
  
<test:tests>
  <test:title>test:report-value function</test:title>
  <test:test id="report-value.1">
    <test:title>Integer</test:title>
    <test:param name="value" select="1" />
    <test:expect select="/test:result">
      <test:result select="1" />
    </test:expect>
  </test:test>
  <test:test id="report-value.2">
    <test:title>Empty Sequence</test:title>
    <test:param name="value" select="()" />
    <test:expect select="/test:result">
      <test:result select="()" />
    </test:expect>
  </test:test>
  <test:test id="report-value.3">
    <test:title>String</test:title>
    <test:param name="value" select="'test'" />
    <test:expect select="/test:result">
      <test:result select="'test'" />
    </test:expect>
  </test:test>
  <test:test id="report-value.4">
    <test:title>URI</test:title>
    <test:param name="value" select="xs:anyURI('test.xml')" />
    <test:expect select="/test:result">
      <test:result select="xs:anyURI('test.xml')" />
    </test:expect>
  </test:test>
  <test:test>
    <test:title>QName</test:title>
    <test:param name="value"
      select="QName('http://www.jenitennison.com/xslt/unit-test', 'tests')" />
    <test:expect select="/test:result">
      <test:result select="QName('http://www.jenitennison.com/xslt/unit-test', 'tests')" />
    </test:expect>
  </test:test>
  <test:test>
    <test:title>Attributes</test:title>
    <test:param name="value" select="/*/@*">
      <doc a="1" b="2" />
    </test:param>
    <test:expect select="/test:result">
      <test:result select="/*/(@* | node())">
        <test:temp a="1" b="2" />
      </test:result>
    </test:expect>
  </test:test>
  <test:test>
    <test:title>Attributes and content</test:title>
    <test:param name="value" select="/*/@*, /*/foo">
      <doc a="1" b="2">
        <foo />
      </doc>
    </test:param>
    <test:expect select="/test:result">
      <test:result select="/*/(@* | node())">
        <test:temp a="1" b="2">
          <foo />
        </test:temp>
      </test:result>
    </test:expect>
  </test:test>
</test:tests>
<xsl:template name="test:report-value">
  <xsl:param name="value" required="yes" />
  <xsl:param name="wrapper-name" select="'t:result'" />
  <xsl:param name="wrapper-ns" select="'http://www.jenitennison.com/xslt/unit-testAlias'" />
  <xsl:element name="{$wrapper-name}" namespace="{$wrapper-ns}">
    <xsl:choose>
      <xsl:when test="$value[1] instance of attribute()">
        <xsl:attribute name="select">/*/(@* | node())</xsl:attribute>
        <xsl:element name="temp" namespace="{$wrapper-ns}">
          <xsl:copy-of select="$value" />
        </xsl:element>
      </xsl:when>
      <xsl:when test="$value instance of node()+">
        <xsl:choose>
          <xsl:when test="$value instance of document-node()">
            <xsl:attribute name="select">/</xsl:attribute>
          </xsl:when>
          <xsl:when test="not($value instance of element()+)">
            <xsl:attribute name="select">/node()</xsl:attribute>
          </xsl:when>
        </xsl:choose>
      	<xsl:choose>
      		<xsl:when test="count($value//node()) > 1000">
      			<xsl:variable name="href" as="xs:string" select="concat(generate-id($value[1]), '.xml')" />
      			<xsl:attribute name="href" select="$href" />
      			<xsl:result-document href="{$href}" format="x:report">
      				<xsl:sequence select="$value" />
      			</xsl:result-document>
      		</xsl:when>
      		<xsl:otherwise>
      			<xsl:apply-templates select="$value" mode="test:report-value" />
      		</xsl:otherwise>
      	</xsl:choose>
      </xsl:when>
      <xsl:otherwise>
        <xsl:attribute name="select">
          <xsl:choose>
            <xsl:when test="empty($value)">()</xsl:when>
            <xsl:when test="$value instance of item()">
              <xsl:value-of select="test:report-atomic-value($value)" />
            </xsl:when>
            <xsl:otherwise>
              <xsl:text>(</xsl:text>
              <xsl:for-each select="$value">
                <xsl:value-of select="test:report-atomic-value(.)" />
                <xsl:if test="position() != last()">, </xsl:if>
              </xsl:for-each>
              <xsl:text>)</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:attribute>        
      </xsl:otherwise>
    </xsl:choose>
  </xsl:element>
</xsl:template>

<xsl:template match="node()" mode="test:report-value">
  <xsl:copy>
    <xsl:copy-of select="@*" />
    <xsl:apply-templates mode="test:report-value" />
  </xsl:copy>
</xsl:template>

<xsl:template match="text()[not(normalize-space())]" mode="test:report-value">
  <t:ws><xsl:value-of select="." /></t:ws>
</xsl:template>

<test:tests>
  <test:title>test:report-atomic-value function</test:title>
  <test:test id="report-atomic-value.1">
    <test:title>String Containing Single Quotes</test:title>
    <test:param name="value" select="'don''t'" />
    <test:expect select="'''don''''t'''" />
  </test:test>
</test:tests>
<xsl:function name="test:report-atomic-value" as="xs:string">
  <xsl:param name="value" as="item()" />
  <xsl:choose>
    <xsl:when test="$value instance of xs:string">
      <xsl:value-of select="concat('''',
                                   replace($value, '''', ''''''),
                                   '''')" />
    </xsl:when>
    <xsl:when test="$value instance of xs:integer or
                    $value instance of xs:decimal or
                    $value instance of xs:double">
      <xsl:value-of select="$value" />
    </xsl:when>
    <xsl:when test="$value instance of xs:QName">
      <xsl:value-of 
        select="concat('QName(''', namespace-uri-from-QName($value), 
                              ''', ''', if (prefix-from-QName($value)) 
                                        then concat(prefix-from-QName($value), ':') 
                                        else '',
                              local-name-from-QName($value), ''')')" />
    </xsl:when>
    <xsl:otherwise>
      <xsl:variable name="type" select="test:atom-type($value)" />
      <xsl:value-of select="concat($type, '(',
                                   test:report-atomic-value(string($value)), ')')" />
    </xsl:otherwise>
  </xsl:choose>
</xsl:function>  
  
<xsl:function name="test:atom-type" as="xs:string">
  <xsl:param name="value" as="xs:anyAtomicType" />
  <xsl:choose>
    <xsl:when test="$value instance of xs:string">xs:string</xsl:when>
    <xsl:when test="$value instance of xs:boolean">xs:boolean</xsl:when>
    <xsl:when test="$value instance of xs:double">xs:double</xsl:when>
    <xsl:when test="$value instance of xs:anyURI">xs:anyURI</xsl:when>
    <xsl:when test="$value instance of xs:dateTime">xs:dateTime</xsl:when>
    <xsl:when test="$value instance of xs:date">xs:date</xsl:when>
    <xsl:when test="$value instance of xs:time">xs:time</xsl:when>
    <xsl:otherwise>xs:anyAtomicType</xsl:otherwise>
  </xsl:choose>  
</xsl:function>
 
<xsl:function name="msxsl:node-set" as="item()*">
  <xsl:param name="rtf" as="item()*" />
  <xsl:sequence select="$rtf" />
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
