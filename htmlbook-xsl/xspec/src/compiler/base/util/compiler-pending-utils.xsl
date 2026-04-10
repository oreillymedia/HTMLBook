<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:x="http://www.jenitennison.com/xslt/xspec"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                exclude-result-prefixes="#all"
                version="3.0">

   <!-- Push and pop explicit reasons for code to be pending. -->
   <xsl:accumulator name="stacked-explicit-pending" as="xs:string*" initial-value="()">
      <!-- Start phase: Prepend string value of @pending, x:pending/@label,
         or x:pending/x:label to stack. Prepending instead of appending
         makes LIFO behavior convenient via tail() function. -->
      <xsl:accumulator-rule match="(x:scenario | x:expect)[@pending]" phase="start"
         select="@pending, $value" />
      <xsl:accumulator-rule match="x:pending" phase="start"
         select="x:label(.), $value" />

      <!-- End phase: Remove newest string from stack. -->
      <xsl:accumulator-rule match="(x:scenario | x:expect)[@pending] | x:pending" phase="end"
         select="tail($value)" />
   </xsl:accumulator>


   <!--
      Returns a string that describes why the given element is pending. The string comes from
      either an explicit reason (@pending or x:pending's label) or an implicit reason (@focus), in
      preference of explicit one over implicit one. The reason string may be a zero-length string.
      Returns an empty sequence if the given element is not pending.
   -->
   <xsl:function name="x:reason-for-pending" as="xs:string?">
      <!-- Any x:* element -->
      <xsl:param name="context-element" as="element()" />

      <xsl:for-each select="$context-element">
         <xsl:choose>
            <xsl:when test="ancestor-or-self::x:scenario[@focus]">
               <!-- No reason for pending. @focus on an ancestor-or-self scenario negates any
                  reasons. -->
            </xsl:when>

            <xsl:when test="
                  $context-element[self::x:param | self::x:variable]
                  /following-sibling::element()
                  /descendant-or-self::x:scenario[@focus]">
               <!-- No reason for pending. @focus on a scenario who inherits variable declaration
                  from the context element negates any reasons. -->
            </xsl:when>

            <xsl:otherwise>
               <!-- The nearest explicit reason (@pending or x:pending's label) -->
               <xsl:variable name="explicit-reason" as="xs:string?"
                  select="accumulator-before('stacked-explicit-pending')[1]" />

               <!-- The first (in document order) implicit reason (@focus) -->
               <xsl:variable name="implicit-reason" as="xs:string?">
                  <xsl:choose>
                     <xsl:when test="ancestor-or-self::x:scenario">
                        <xsl:sequence select="
                              root()
                              /descendant-or-self::x:scenario[@focus][1]
                              /@focus
                              /string()" />
                     </xsl:when>

                     <xsl:otherwise>
                        <!-- No implicit reason for pending. Only scenario-level elements are
                           supposed to have implicit reason. -->
                     </xsl:otherwise>
                  </xsl:choose>
               </xsl:variable>

               <!-- Prefer explicit one to implicit one -->
               <xsl:sequence select="($explicit-reason, $implicit-reason)[1]" />
            </xsl:otherwise>
         </xsl:choose>
      </xsl:for-each>
   </xsl:function>

   <!--
      Creates @pending based on the given reason string. The value of @pending is zero-length if the
      reason is a zero-length string.
      Returns an empty sequence if the reason is an empty sequence.
   -->
   <xsl:function name="x:pending-attribute-from-reason" as="attribute(pending)?">
      <xsl:param name="reason-for-pending" as="xs:string?" />

      <xsl:for-each select="$reason-for-pending">
         <xsl:attribute name="pending" select="." />
      </xsl:for-each>
   </xsl:function>

</xsl:stylesheet>