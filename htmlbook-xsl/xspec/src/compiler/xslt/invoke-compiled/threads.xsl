<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.w3.org/1999/XSL/TransformAlias"
                xmlns:x="http://www.jenitennison.com/xslt/xspec"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                exclude-result-prefixes="#all"
                version="3.0">

   <!--
      mode="x:threads"
      Implements multi-threading.
   -->

   <xsl:template match="document-node()" as="element()*" mode="x:threads">
      <!-- xsl:call-template elements originating from x:scenario -->
      <xsl:variable name="scenario-invokers" as="element(xsl:call-template)*"
         select="xsl:call-template[processing-instruction(origin) eq 'scenario']" />

      <!-- All the invocation instructions originating from x:scenario must be adjacent so that they
         can be grouped in a single group. This check is to make the implementation more robust or
         future-resistant as the compiler code evolves. -->
      <xsl:for-each select="
            node()
            [not(. intersect $scenario-invokers)]
            [. >> $scenario-invokers[1]]
            [$scenario-invokers[last()] >> .]">
         <xsl:message terminate="yes">
            <xsl:call-template name="x:prefix-diag-message">
               <xsl:with-param name="message"
                  select="'Unexpected node between invocation instructions of compiled scenario.'" />
            </xsl:call-template>
         </xsl:message>
      </xsl:for-each>

      <!-- Group the adjacent xsl:call-template elements originating from x:scenario. The other
         nodes (actually, xsl:call-template elements (from x:expect) and xsl:variable elements (from
         x:param and x:variable)) are grouped individually. -->
      <xsl:for-each-group select="node() treat as element()*" group-adjacent="
            if (. intersect $scenario-invokers) then
               0
            else
               position()">
         <xsl:apply-templates select="." mode="#current" />
      </xsl:for-each-group>
   </xsl:template>

   <xsl:template match="xsl:call-template[processing-instruction(origin) eq 'scenario']"
      as="element()+" mode="x:threads">
      <!-- x:description or x:scenario invoking the current xsl:call-template -->
      <xsl:param name="tunnel_invoker-description-or-scenario" as="element()" required="yes"
         tunnel="yes" />

      <xsl:variable name="child-scenario-count" as="xs:integer" select="current-group() => count()" />
      <xsl:variable name="invoker-description-or-scenario-wants-to-enable-threads" as="xs:boolean"
         select="x:wants-to-enable-threads($tunnel_invoker-description-or-scenario)" />

      <xsl:if test="$invoker-description-or-scenario-wants-to-enable-threads">
         <xsl:variable name="threads-attr" as="attribute(threads)"
            select="$tunnel_invoker-description-or-scenario/@threads" />

         <variable name="{x:known-UQName('impl:thread-count')}" as="{x:known-UQName('xs:integer')}"
            use-when="${x:known-UQName('impl:thread-aware')}">
            <xsl:if test="starts-with($threads-attr, '#') => not()">
               <!-- @threads may use namespace prefixes and/or the default namespace such as
                  xs:QName('foo') -->
               <xsl:sequence select="x:copy-of-namespaces($tunnel_invoker-description-or-scenario)" />
            </xsl:if>

            <xsl:attribute name="select">
               <xsl:choose>
                  <xsl:when test="$threads-attr eq '#child-scenario-count'">
                     <xsl:sequence select="$child-scenario-count" />
                  </xsl:when>
                  <xsl:when test="$threads-attr eq '#logical-processor-count'">
                     <xsl:text expand-text="yes">(${x:known-UQName('impl:logical-processor-count')}, {$child-scenario-count}) => min()</xsl:text>
                  </xsl:when>
                  <xsl:otherwise>
                     <xsl:text expand-text="yes">if (not(({$threads-attr}) instance of {x:known-UQName('xs:integer')})) </xsl:text>
                     <xsl:text expand-text="yes">then error((), '{path($threads-attr)} is not an integer') </xsl:text>
                     <xsl:text expand-text="yes">else min((({$threads-attr})[if (. castable as {x:known-UQName('xs:positiveInteger')}) then true() else error((), '{path($threads-attr)} is not positive')], {$child-scenario-count})) </xsl:text>
                  </xsl:otherwise>
               </xsl:choose>
            </xsl:attribute>
         </variable>

         <message use-when="${x:known-UQName('impl:thread-aware')}">
            <text xsl:expand-text="yes">Invoking {$child-scenario-count} child scenarios using </text>
            <value-of select="${x:known-UQName('impl:thread-count')}" />
            <text> thread(s) with </text>
            <value-of select="${x:known-UQName('impl:logical-processor-count')}" />
            <text> logical processor(s)</text>
         </message>
      </xsl:if>

      <for-each select="1 to {$child-scenario-count}">
         <xsl:if test="$invoker-description-or-scenario-wants-to-enable-threads">
            <xsl:attribute name="saxon:threads" namespace="{$x:saxon-namespace}"
               select="'{$' || x:known-UQName('impl:thread-count') || '}'" />
         </xsl:if>
         <choose>
            <xsl:for-each select="current-group()">
               <when test=". eq {position()}">
                  <!-- Identical copy except the 'origin' processing instruction -->
                  <xsl:copy>
                     <xsl:apply-templates select="attribute()" mode="#current" />
                     <xsl:apply-templates select="node() except processing-instruction(origin)"
                        mode="#current" />
                  </xsl:copy>
               </when>
            </xsl:for-each>
            <otherwise>
               <message terminate="yes">
                  <xsl:text>ERROR: Unhandled scenario invocation</xsl:text>
               </message>
            </otherwise>
         </choose>
      </for-each>
   </xsl:template>

</xsl:stylesheet>