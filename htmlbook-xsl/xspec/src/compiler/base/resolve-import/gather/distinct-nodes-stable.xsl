<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:local="urn:x-xspec:compiler:base:resolve-import:gather:gather-descriptions:local"
                xmlns:x="http://www.jenitennison.com/xslt/xspec"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                exclude-result-prefixes="#all"
                version="3.0">

   <!-- Removes duplicate nodes from a sequence of nodes. (Removes a node if it appears
      in a prior position of the sequence.)
      This function does not sort nodes in document order.
      
      The xsl:function/xsl:sequence/@select attribute is based on the XPath expression in
      "XPath and XQuery Functions and Operators 3.1" (W3C Recommendation 21 March 2017)
      > "D Other Functions (Non-Normative)" > "D.4 Illustrative user-written functions"
      > "D.4.5 eg:distinct-nodes-stable"
      http://www.w3.org/TR/xpath-functions-31/#func-distinct-nodes-stable
      (Modifications: Parameter name)
   -->
   <xsl:function name="local:distinct-nodes-stable" as="node()*">
      <xsl:param name="nodes" as="node()*"/>

      <xsl:sequence select="$nodes[empty(subsequence($nodes, 1, position() - 1) intersect .)]"/>
   </xsl:function>

</xsl:stylesheet>
<!--
  LICENSE NOTICE

  [Copyright](https://www.w3.org/Consortium/Legal/ipr-notice#Copyright) © 2017 [W3C](https://www.w3.org/)® ([MIT](https://www.csail.mit.edu/), [ERCIM](https://www.ercim.eu/), [Keio](https://www.keio.ac.jp/), [Beihang](http://ev.buaa.edu.cn/)), All Rights Reserved.
  W3C [liability](https://www.w3.org/Consortium/Legal/ipr-notice#Legal_Disclaimer), [trademark](https://www.w3.org/Consortium/Legal/ipr-notice#W3C_Trademarks), [document use](https://www.w3.org/Consortium/Legal/copyright-documents), and [software licensing](http://www.w3.org/Consortium/Legal/copyright-software) rules apply.

  This software or document includes material copied from or derived from "XPath and XQuery Functions and Operators 3.1", W3C Recommendation 21 March 2017. https://www.w3.org/TR/xpath-functions-31/
  https://www.w3.org/copyright/software-license-2023/
  
  Text of W3C Document License: ../../../../../third-party-licenses/W3C-document-license-2023.txt
  Text of W3C Software License: ../../../../../third-party-licenses/W3C-software-license-2023.txt
-->