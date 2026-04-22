<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:deq="urn:x-xspec:common:deep-equal"
                xmlns:local="urn:x-xspec:common:deep-equal:local"
                xmlns:x="http://www.jenitennison.com/xslt/xspec"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:wrap="urn:x-xspec:common:wrap"
                exclude-result-prefixes="#all"
                version="3.0">

   <!--
      TODO: Implement this debugging feature??
      TODO: @name must not pollute the other modules: xspec/xspec#985
   -->
   <!--<xsl:param name="debug" as="xs:boolean" select="true()" />-->

   <!-- $flags
      w : Ignores descendant whitespace-only text nodes except the ones in <x:ws>
      d : Does not wrap document nodes
      1 : Simulates XSLT version 1.0 -->
   <xsl:function name="deq:deep-equal" as="xs:boolean">
      <xsl:param name="seq1" as="item()*" />
      <xsl:param name="seq2" as="item()*" />
      <xsl:param name="flags" as="xs:string" />

      <!-- Using a $param in @use-when does not work.  TODO: What to do? At run time? -->
      <!-- See also ../../misc/archive/ for x:node-path(). -->
      <!--
      <xsl:if test="$seq1 instance of node()" use-when="$debug">
         <xsl:message select="'DEEP-EQUAL: SEQ1:', x:node-path($seq1)" />
      </xsl:if>
      <xsl:if test="$seq2 instance of node()" use-when="$debug">
         <xsl:message select="'DEEP-EQUAL: SEQ2:', x:node-path($seq2)" />
      </xsl:if>
      -->

      <xsl:variable name="result" as="xs:boolean">
         <xsl:choose>
            <xsl:when test="contains($flags, '1')">
               <xsl:sequence select="local:deep-equal-v1($seq1, $seq2, $flags)" />
            </xsl:when>

            <xsl:when test="($seq1 instance of attribute()+) and
               (some $att in $seq1 satisfies (node-name($att) = QName($x:xspec-namespace,'x:attrs') and string($att) eq '...'))">
               <!-- Support attribute x:attrs="..." in $seq1 -->
               <xsl:variable name="seq1-without-x-other" as="attribute()*"
                  select="$seq1[not(node-name(.) = QName($x:xspec-namespace,'x:attrs'))]" />
               <xsl:variable name="seq2-without-extras" as="attribute()*"
                  select="$seq2[node-name(.) = $seq1/node-name()]" />
               <xsl:sequence
                  select="deq:deep-equal(
                     $seq1-without-x-other,
                     $seq2-without-extras,
                     $flags
                  )" />
            </xsl:when>

            <xsl:when test="empty($seq1) or empty($seq2)">
               <xsl:sequence select="empty($seq1) and empty($seq2)" />
            </xsl:when>

            <xsl:when test="count($seq1) = count($seq2)">
               <xsl:sequence
                  select="
                     every $i in (1 to count($seq1)) 
                     satisfies deq:item-deep-equal($seq1[$i], $seq2[$i], $flags)" />
            </xsl:when>

            <xsl:when test="$seq1 instance of text() and
                            $seq2 instance of text()+">
               <xsl:variable name="seq2" as="text()">
                  <xsl:value-of select="$seq2" separator="" />
               </xsl:variable>
               <xsl:sequence select="deq:deep-equal($seq1, $seq2, $flags)" />
            </xsl:when>

            <xsl:when test="wrap:wrappable-sequence($seq1) and wrap:wrappable-sequence($seq2)
               and not(contains($flags, 'd'))">
               <xsl:variable name="seq1doc" as="document-node()" select="wrap:wrap-nodes($seq1)" />
               <xsl:variable name="seq2doc" as="document-node()" select="wrap:wrap-nodes($seq2)" />

               <xsl:choose>
                  <xsl:when
                     test="
                        count($seq1doc/node()) != count($seq1)
                        or count($seq2doc/node()) != count($seq2)">
                     <xsl:sequence
                        select="deq:deep-equal($seq1doc/node(), $seq2doc/node(), $flags)" />
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
      </xsl:variable>

      <!-- Using a $param in @use-when does not work.  TODO: What to do? At run time? -->
      <!--
      <xsl:message select="'DEEP-EQUAL: RESULT:', $result" use-when="$debug" />
      -->

      <xsl:sequence select="$result" />
   </xsl:function>

   <xsl:function name="local:deep-equal-v1" as="xs:boolean">
      <xsl:param name="seq1" as="item()*" />
      <xsl:param name="seq2" as="item()*" />
      <xsl:param name="flags" as="xs:string" />

      <xsl:variable name="seq2-adapted" as="xs:anyAtomicType?">
         <xsl:if test="$seq2 instance of text()+">
            <xsl:variable name="seq2-string" as="xs:string" select="string-join($seq2)" />

            <xsl:choose>
               <xsl:when test="$seq1 instance of xs:string">
                  <xsl:sequence select="$seq2-string" />
               </xsl:when>
               <xsl:when test="$seq1 instance of xs:double">
                  <xsl:sequence select="$seq2-string[. castable as xs:double] => xs:double()" />
               </xsl:when>
               <xsl:when test="$seq1 instance of xs:decimal">
                  <xsl:sequence select="$seq2-string[. castable as xs:decimal] => xs:decimal()" />
               </xsl:when>
            </xsl:choose>
         </xsl:if>
      </xsl:variable>

      <xsl:sequence
         select="
            deq:deep-equal(
               $seq1,
               ($seq2-adapted, $seq2)[1],
               translate($flags, '1', '')
            )" />
   </xsl:function>

   <!--
      This function should be local:. But ../../test/deep-equal.xspec requires this to be exposed.
   -->
   <xsl:function name="deq:item-deep-equal" as="xs:boolean">
      <xsl:param name="item1" as="item()" />
      <xsl:param name="item2" as="item()" />
      <xsl:param name="flags" as="xs:string" />

      <xsl:choose>
         <xsl:when test="$item1 instance of node() and
                         $item2 instance of node()">
            <xsl:sequence select="deq:node-deep-equal($item1, $item2, $flags)" />
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

   <!--
      This function should be local:. But ../../test/deep-equal.xspec requires this to be exposed.
   -->
   <xsl:function name="deq:node-deep-equal" as="xs:boolean">
      <xsl:param name="node1" as="node()" />
      <xsl:param name="node2" as="node()" />
      <xsl:param name="flags" as="xs:string" />

      <xsl:choose>
         <xsl:when test="$node1 instance of document-node() and
                         $node2 instance of document-node()">
            <xsl:variable name="children1" as="node()*"
               select="deq:sorted-children($node1, $flags)" />
            <xsl:variable name="children2" as="node()*" 
               select="deq:sorted-children($node2, $flags)" />
            <xsl:sequence select="deq:deep-equal($children1, $children2, $flags)" />
         </xsl:when>

         <xsl:when test="$node1 instance of element() and
                         $node2 instance of element()">
            <xsl:sequence select="local:element-deep-equal($node1, $node2, $flags)" />
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
                         ($node1 instance of comment() and
                          $node2 instance of comment()) or
                         ($node1 instance of processing-instruction() and
                          $node2 instance of processing-instruction()) or
                         ($node1 instance of namespace-node() and
                          $node2 instance of namespace-node())">
            <xsl:sequence select="
                  deep-equal(node-name($node1), node-name($node2))
                  and (string($node1) = (string($node2), '...'))" />
         </xsl:when>

         <xsl:otherwise>
            <xsl:sequence select="false()" />
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>

   <xsl:function name="local:element-deep-equal" as="xs:boolean">
      <xsl:param name="elem1" as="element()" />
      <xsl:param name="elem2" as="element()" />
      <xsl:param name="flags" as="xs:string" />

      <xsl:variable name="node-name-equal" as="xs:boolean"
         select="node-name($elem1) eq node-name($elem2)" />

      <xsl:variable name="attrs-equal" as="xs:boolean"
         select="
            deq:deep-equal(
               local:sort-named-nodes($elem1/attribute()),
               local:sort-named-nodes($elem2/attribute()),
               $flags
            )" />

      <xsl:variable name="children-equal" as="xs:boolean"
         select="
            $elem1[count(node()) eq 1][text() = '...']
            or
            deq:deep-equal(
               deq:sorted-children($elem1, $flags),
               deq:sorted-children($elem2, $flags),
               $flags
            )" />

      <xsl:sequence select="$node-name-equal and $attrs-equal and $children-equal" />
   </xsl:function>

   <!--
      This function should be local:. But ../../test/deep-equal.xspec requires this to be exposed.
   -->
   <xsl:function name="deq:sorted-children" as="node()*">
      <xsl:param name="node" as="node()" />
      <xsl:param name="flags" as="xs:string" />

      <xsl:variable name="ignorable-ws-only-text-nodes" as="text()*">
         <xsl:if test="contains($flags, 'w') and not($node/self::x:ws)">
            <xsl:sequence select="$node/text()[normalize-space() => not()]" />
         </xsl:if>
      </xsl:variable>
      <xsl:sequence select="$node/child::node() except $ignorable-ws-only-text-nodes" />
   </xsl:function>

   <xsl:function name="local:sort-named-nodes" as="node()*">
      <xsl:param name="nodes" as="node()*" />

      <xsl:perform-sort select="$nodes">
         <xsl:sort select="namespace-uri()" />
         <xsl:sort select="local-name()" />
      </xsl:perform-sort>
   </xsl:function>

</xsl:stylesheet>