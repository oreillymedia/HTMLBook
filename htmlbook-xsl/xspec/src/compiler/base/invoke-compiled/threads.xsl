<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:x="http://www.jenitennison.com/xslt/xspec"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                exclude-result-prefixes="#all"
                version="3.0">

   <!--
      mode="x:threads"
      This mode makes the invocation instructions of compiled x:scenario or x:expect parallel
      (multi-threading). Actual implementation depends on language (XSLT or XQuery).
   -->
   <xsl:mode name="x:threads" on-multiple-match="fail" on-no-match="shallow-copy" />

   <!--
      Utils for multi-threading
   -->

   <!-- Returns true if the given x:description or x:scenario wants to enable multi-threading.
      Whether multi-threading is actually enabled or not depends on language (XSLT or XQuery) and
      its runtime processor. -->
   <xsl:function name="x:wants-to-enable-threads" as="xs:boolean">
      <!-- x:description or x:scenario -->
      <xsl:param name="description-or-scenario" as="element()" />

      <!-- The number of child scenarios, taking x:pending into account -->
      <xsl:variable name="child-scenario-count" as="xs:integer"
         select="$description-or-scenario/(. | x:pending)/x:scenario => count()" />

      <xsl:sequence select="$description-or-scenario/@threads and ($child-scenario-count ge 2)" />
   </xsl:function>

</xsl:stylesheet>
