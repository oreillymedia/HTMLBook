<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:x="http://www.jenitennison.com/xslt/xspec"
   xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   exclude-result-prefixes="#all" version="3.0">

   <xsl:function name="x:selection-from-doc" as="xs:string">
      <xsl:param name="element" as="element()"/>
      <!-- When testing XProc, if $element is x:expect[@port][not(@test)], wrap each embedded
         child node or selected node in a document node. The wrapping makes sense because if an
         XProc step returns a node at all, it's always a document node. Per-node wrapping makes
         sense because of section "3.3. Creating documents from XDM step results" in the XProc 3.1
         specification. https://spec.xproc.org/3.1/xproc/ -->
     <xsl:variable name="wrap-selected-nodes" expand-text="yes" as="xs:string"
        >({$element/@select}) => {x:known-UQName('wrap:wrap-each')}()</xsl:variable>
     <xsl:variable name="wrap-embedded-nodes" expand-text="yes" as="xs:string"
        >. ! {x:known-UQName('wrap:wrap-each')}(child::node())</xsl:variable>
      <xsl:sequence select="
            (
            $wrap-selected-nodes[
              $element/self::x:expect[@port][not(@test)][@select] or
              $element/self::x:input[@select]
            ],
            $element/@select,
            '.'[$element/@href],
            $wrap-embedded-nodes[
              $element/self::x:expect[@port][not(@test)] or
              $element/self::x:input
            ],
            'node()'
            )[1]"/>
   </xsl:function>
</xsl:stylesheet>