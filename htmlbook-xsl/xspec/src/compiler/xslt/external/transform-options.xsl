<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.w3.org/1999/XSL/TransformAlias"
                xmlns:local="urn:x-xspec:compiler:xslt:external:transform-options:local"
                xmlns:x="http://www.jenitennison.com/xslt/xspec"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                exclude-result-prefixes="#all"
                version="3.0">

   <!--
      Constructs options for transform()
   -->
   <xsl:template name="x:transform-options" as="element(xsl:variable)">
      <xsl:context-item as="element(x:scenario)" use="required" />

      <xsl:param name="invocation-type" as="xs:string" required="yes" />
      <xsl:param name="call" as="element(x:call)?" required="yes" tunnel="yes" />
      <xsl:param name="context" as="element(x:context)?" required="yes" tunnel="yes" />

      <variable name="{x:known-UQName('impl:transform-options')}" as="map({x:known-UQName('xs:string')}, item()*)">
         <map>
            <!--
               Common options
            -->

            <map-entry key="'delivery-format'" select="'raw'" />

            <!-- 'stylesheet-node' might be faster than 'stylesheet-location' when repeated. (Just a guess.
               Haven't tested.) But 'stylesheet-node' disables $x:result?err?line-number on @catch=true. -->
            <map-entry key="'stylesheet-location'">
               <xsl:value-of select="/x:description/@stylesheet" />
            </map-entry>

            <!-- To enable SUT to use XSLT 4.0 features, the options for transform()
               must include xslt-version="4.0", according to
               https://www.saxonica.com/documentation12/index.html#!functions/fn/transform -->
            <xsl:if test="x:xslt-version(.) ge 4">
               <map-entry key="'xslt-version'">
                  <xsl:value-of select="x:xslt-version(.) => x:decimal-string()"/>
               </map-entry>
            </xsl:if>

            <xsl:where-populated>
               <!-- Cumulative x:param elements for stylesheet. In document order. -->
               <xsl:variable name="stylesheet-cumulative-params" as="element(x:param)*" select="
                     (: Global x:param :)
                     /x:description/x:param
                     
                     (: Scenario-level x:param stacked outside the current x:scenario :)
                     | accumulator-before('stacked-vardecls')/self::x:param
                     
                     (: Local x:param. We can take all child::x:param, because the XSpec schema
                        forces x:param to be placed before x:call, x:context and x:expect. :)
                     | child::x:param" />

               <!-- Remove overridden ones -->
               <xsl:variable name="stylesheet-effective-params" as="element(x:param)*" select="
                     $stylesheet-cumulative-params
                     [not(
                        (
                           subsequence($stylesheet-cumulative-params, position() + 1)
                           ! x:variable-UQName(.)
                        )
                        = x:variable-UQName(.)
                     )]" />

               <map-entry key="'static-params'">
                  <xsl:where-populated>
                     <map>
                        <xsl:sequence
                           select="
                              $stylesheet-effective-params[x:yes-no-synonym(@static, false())]
                              ! local:param-to-map-entry(.)" />
                     </map>
                  </xsl:where-populated>
               </map-entry>

               <map-entry key="'stylesheet-params'">
                  <xsl:where-populated>
                     <map>
                        <xsl:sequence
                           select="
                              $stylesheet-effective-params[x:yes-no-synonym(@static, false()) => not()]
                              ! local:param-to-map-entry(.)" />
                     </map>
                  </xsl:where-populated>
               </map-entry>
            </xsl:where-populated>

            <if test="${x:known-UQName('x:saxon-config')} => exists()">
               <!-- Check that the variable appears to be a Saxon configuration -->
               <choose>
                  <when test="${x:known-UQName('x:saxon-config')} instance of element({x:known-UQName('config:configuration')})" />
                  <when test="${x:known-UQName('x:saxon-config')} instance of document-node(element({x:known-UQName('config:configuration')}))" />
                  <otherwise>
                     <message terminate="yes">
                        <!-- Use URIQualifiedName for displaying the $x:saxon-config variable name,
                           for we do not know the name prefix of the originating variable. -->
                        <xsl:text expand-text="yes">ERROR: ${x:known-UQName('x:saxon-config')} does not appear to be a Saxon configuration</xsl:text>
                     </message>
                  </otherwise>
               </choose>

               <!-- cache must be false(): https://saxonica.plan.io/issues/4667 -->
               <map-entry key="'cache'" select="false()" />

               <map-entry key="'vendor-options'">
                  <map>
                     <map-entry key="QName('{$x:saxon-namespace}', 'configuration')"
                        select="${x:known-UQName('x:saxon-config')}" />
                  </map>
               </map-entry>
            </if>

            <!--
               Options for template invocation types
            -->
            <xsl:for-each select="
                  $context[$invocation-type eq 'apply-templates'],
                  $call[$invocation-type eq 'call-template']">
               <xsl:where-populated>
                  <map-entry key="'template-params'">
                     <xsl:where-populated>
                        <map>
                           <xsl:sequence
                              select="
                                 x:param[x:yes-no-synonym(@tunnel, false()) => not()]
                                 ! local:param-to-map-entry(.)" />
                        </map>
                     </xsl:where-populated>
                  </map-entry>
                  <map-entry key="'tunnel-params'">
                     <xsl:where-populated>
                        <map>
                           <xsl:sequence
                              select="
                                 x:param[x:yes-no-synonym(@tunnel, false())]
                                 ! local:param-to-map-entry(.)" />
                        </map>
                     </xsl:where-populated>
                  </map-entry>
               </xsl:where-populated>
            </xsl:for-each>

            <!--
               Options for a specific invocation type
            -->
            <xsl:choose>
               <xsl:when test="$invocation-type eq 'call-template'">
                  <map-entry key="'initial-template'"
                     select="{x:QName-expression-from-EQName-ignoring-default-ns($call/@template, $call)}" />
                  <!-- 'global-context-item' option is set in x:compile-scenario template -->
               </xsl:when>

               <xsl:when test="$invocation-type eq 'call-function'">
                  <map-entry key="'function-params'">
                     <xsl:attribute name="select">
                        <xsl:text>[</xsl:text>
                        <xsl:value-of separator=", ">
                           <xsl:for-each select="$call/x:param">
                              <xsl:sort select="xs:integer(@position)" />
                              <xsl:sequence select="local:param-to-select-attr(.)" />
                           </xsl:for-each>
                        </xsl:value-of>
                        <xsl:text>]</xsl:text>
                     </xsl:attribute>
                  </map-entry>
                  <map-entry key="'initial-function'"
                     select="{x:QName-expression-from-EQName-ignoring-default-ns($call/@function, $call)}" />
                  <!-- 'global-context-item' option is set in x:compile-scenario template -->
               </xsl:when>

               <xsl:when test="$invocation-type eq 'apply-templates'">
                  <map-entry
                     key="if (${x:variable-UQName($context)} instance of node()) then 'source-node' else 'initial-match-selection'"
                     select="${x:variable-UQName($context)}" />
                  <xsl:for-each select="$context[@mode]">
                     <map-entry key="'initial-mode'"
                        select="{x:QName-expression-from-EQName-ignoring-default-ns(@mode, .)}" />
                  </xsl:for-each>
               </xsl:when>
            </xsl:choose>
         </map>
      </variable>
   </xsl:template>

   <!--
      Local functions
   -->

   <!--
      Transforms x:param to xsl:map-entry
   -->
   <xsl:function name="local:param-to-map-entry" as="element(xsl:map-entry)">
      <xsl:param name="param" as="element(x:param)" />

      <map-entry key="{$param ! x:QName-expression-from-EQName-ignoring-default-ns(@name, .)}">
         <xsl:sequence select="local:param-to-select-attr($param)" />
      </map-entry>
   </xsl:function>

   <!--
      Transforms x:param to @select which is connected to the generated xsl:variable
   -->
   <xsl:function name="local:param-to-select-attr" as="attribute(select)">
      <xsl:param name="param" as="element(x:param)" />

      <xsl:attribute name="select" select="'$' || x:variable-UQName($param)" />
   </xsl:function>

</xsl:stylesheet>