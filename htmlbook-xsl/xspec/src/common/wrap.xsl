<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:wrap="urn:x-xspec:common:wrap"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                exclude-result-prefixes="#all"
                version="3.0">

   <!-- Returns true if every item in sequence can be wrapped in document node.
      Empty sequence is considered to be able to be wrapped. -->
   <xsl:function name="wrap:wrappable-sequence" as="xs:boolean">
      <xsl:param name="sequence" as="item()*" />

      <xsl:sequence select="every $item in $sequence satisfies wrap:wrappable-node($item)" />
   </xsl:function>

   <!-- Returns true if item is node and can be wrapped in document node -->
   <xsl:function name="wrap:wrappable-node" as="xs:boolean">
      <xsl:param name="item" as="item()" />

      <!-- Document node cannot wrap attribute node or namespace node, according to
         https://www.w3.org/TR/xslt-30/#err-XTDE0420 -->
      <xsl:sequence
         select="
            $item instance of node()
            and not($item instance of attribute()
                    or $item instance of namespace-node())" />
   </xsl:function>

   <!-- Wraps nodes in document node with their type annotations kept -->
   <xsl:function name="wrap:wrap-nodes" as="document-node()">
      <xsl:param name="nodes" as="node()*" />

      <!-- $wrap aims to create an implicit document node as described
         in https://www.w3.org/TR/xslt-30/#temporary-trees.
         So its xsl:variable must not have @as or @select.
         Do not use xsl:document or xsl:copy-of: xspec/xspec#47 -->
      <xsl:variable name="wrap">
         <xsl:sequence select="$nodes" />
      </xsl:variable> 
      <xsl:sequence select="$wrap" />
   </xsl:function>

   <!-- wrap:wrap-each individually wraps each node in $nodes in a document node.
        Example: (<a/>, <b/>, <c/>) yields a document node containing <a/>,
        one containing <b/>, and one containing <c/>.
        
        Unwrappable items pass through unchanged.
   -->
   <xsl:function name="wrap:wrap-each" as="item()*">
      <xsl:param name="items" as="item()*"/>
      <xsl:for-each select="$items">
         <xsl:sequence select="if (wrap:wrappable-node(.)) then wrap:wrap-nodes(.) else ."/>
      </xsl:for-each>
   </xsl:function>

   <!-- wrap:unwrap-text-nodes returns each item unchanged, except that if an item is
        a text node wrapped in a document node, the function returns the text node in
        that position of the sequence.
   -->
   <xsl:function name="wrap:unwrap-text-nodes" as="item()*">
      <xsl:param name="items" as="item()*"/>
      <xsl:for-each select="$items">
         <xsl:choose>
            <xsl:when test="not(. instance of document-node())">
               <xsl:sequence select="."/>
            </xsl:when>
            <xsl:when test="child::node() instance of text()">
               <xsl:sequence select="text()"/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:sequence select="."/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:for-each>
   </xsl:function>

</xsl:stylesheet>