<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:local="urn:x-xspec:compiler:base:compile:compile-child-scenarios-or-expects:local"
                xmlns:x="http://www.jenitennison.com/xslt/xspec"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                exclude-result-prefixes="#all"
                version="3.0">

   <!--
      Drive the compilation of (child::x:scenario | child::x:expect) to either XSLT named templates
      or XQuery functions, taking x:pending into account.
   -->
   <xsl:template name="x:compile-child-scenarios-or-expects" as="node()*">
      <!-- Context item is x:description or x:scenario -->
      <xsl:context-item as="element()" use="required" />

      <xsl:variable name="this" select="." as="element()"/>
      <xsl:if test="empty($this[self::x:description|self::x:scenario])">
         <xsl:message terminate="yes">
            <xsl:call-template name="x:prefix-diag-message">
               <xsl:with-param name="message" select="'$this must be a description or a scenario'" />
            </xsl:call-template>
         </xsl:message>
      </xsl:if>

      <xsl:apply-templates select="$this/element()" mode="local:compile-scenarios-or-expects" />
   </xsl:template>

   <!--
      mode="local:compile-scenarios-or-expects"
      Must be "fired" by the named template "x:compile-child-scenarios-or-expects".
   -->
   <xsl:mode name="local:compile-scenarios-or-expects" on-multiple-match="fail"
      on-no-match="deep-skip" />

   <!--
      At x:pending elements, just move on to the children. Pending status and reason are accounted
      for in descendant context.
   -->
   <xsl:template match="x:pending" as="node()+" mode="local:compile-scenarios-or-expects">
      <xsl:apply-templates select="element()" mode="#current" />
   </xsl:template>

   <!--
      Compile x:scenario.
   -->
   <xsl:template match="x:scenario" as="node()+" mode="local:compile-scenarios-or-expects">
      <xsl:param name="call" as="element(x:call)?" tunnel="yes" />
      <xsl:param name="context" as="element(x:context)?" tunnel="yes" />

      <xsl:variable name="reason-for-pending" as="xs:string?" select="x:reason-for-pending(.)" />

      <!-- The new context. -->
      <xsl:variable name="new-context" as="element(x:context)?">
         <xsl:choose>
            <xsl:when test="x:context">
               <xsl:copy select="x:context">
                  <xsl:sequence select="($context, .) ! attribute()" />

                  <xsl:variable name="local-params" as="element(x:param)*" select="x:param"/>
                  <xsl:sequence
                     select="
                        $context/x:param[not(@name = $local-params/@name)],
                        $local-params"/>

                  <xsl:sequence
                     select="
                        if (node() except x:param) then
                           (node() except x:param)
                        else
                           $context/(node() except x:param)" />
               </xsl:copy>
            </xsl:when>
            <xsl:otherwise>
               <xsl:sequence select="$context"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:variable>

      <!-- The new call. -->
      <xsl:variable name="new-call" as="element(x:call)?">
         <xsl:choose>
            <xsl:when test="x:call">
               <xsl:copy select="x:call">
                  <xsl:sequence select="($call, .) ! attribute()" />

                  <xsl:variable name="is-function-call" as="xs:boolean"
                     select="($call, .)/@function => exists()" />
                  <xsl:variable name="local-params" as="element()*">
                     <!-- Sequence type of this variable is:
                        * For call to template or function: element(x:param)*
                        * For call to step: element(x:input)*, element(x:option)*
                     -->
                     <xsl:for-each select="x:param | x:input | x:option">
                        <xsl:copy>
                           <xsl:if test="$is-function-call">
                              <xsl:attribute name="position" select="position()" />
                           </xsl:if>
                           <xsl:sequence select="attribute() | node()" />
                        </xsl:copy>
                     </xsl:for-each>
                  </xsl:variable>

                  <xsl:sequence
                     select="
                        $call/(x:param | x:input | x:option)
                        [not(@name = $local-params/@name)]
                        [not(@port = $local-params/@port)]
                        [not(@position = $local-params/@position)],
                        $local-params"/>
               </xsl:copy>
               <!-- TODO: Test that "x:call/(node() except (x:param | x:input | x:option))" is empty. -->
            </xsl:when>
            <xsl:otherwise>
               <xsl:sequence select="$call"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:variable>

      <!-- Check duplicate parameter name/position-->
      <xsl:variable name="dup-param-error-string" as="xs:string?"
         select="
            (
               ($new-call, $new-context) ! local:param-dup-name-error-string(.),
               $new-call[@function] ! local:param-dup-position-error-string(.)
            )[1]" />
      <xsl:if test="$dup-param-error-string">
         <xsl:message terminate="yes">
            <xsl:call-template name="x:prefix-diag-message">
               <xsl:with-param name="message" select="$dup-param-error-string" />
            </xsl:call-template>
         </xsl:message>
      </xsl:if>

      <!-- Dispatch to a language-specific (XSLT, XQuery, or XProc) worker template -->
      <xsl:call-template name="x:compile-scenario">
         <xsl:with-param name="call" select="$new-call" tunnel="yes" />
         <xsl:with-param name="context" select="$new-context" tunnel="yes" />
         <xsl:with-param name="reason-for-pending" select="$reason-for-pending" />
         <xsl:with-param name="run-sut-now"
            select="empty($reason-for-pending) and x:expect[empty(x:reason-for-pending(.))]" />
      </xsl:call-template>
   </xsl:template>

   <!--
      Compile x:expect.
   -->
   <xsl:template match="x:expect" as="node()+" mode="local:compile-scenarios-or-expects">
      <xsl:param name="context" as="element(x:context)?" required="yes" tunnel="yes" />

      <xsl:variable name="reason-for-pending" as="xs:string?" select="x:reason-for-pending(.)" />

      <!-- Dispatch to a language-specific (XSLT or XQuery) worker template -->
      <xsl:call-template name="x:compile-expect">
         <xsl:with-param name="reason-for-pending" select="$reason-for-pending" />
         <xsl:with-param name="param-uqnames" as="xs:string*">
            <xsl:if test="empty($reason-for-pending)">
               <xsl:sequence select="x:known-UQName('x:result')" />
            </xsl:if>
            <xsl:sequence select="accumulator-before('stacked-vardecls-distinct-uqnames')" />
         </xsl:with-param>
      </xsl:call-template>
   </xsl:template>

   <!--
      Local functions
   -->

   <!-- Returns an error string if the given element has duplicate x:param/@name -->
   <xsl:function name="local:param-dup-name-error-string" as="xs:string?">
      <!-- x:call or x:context -->
      <xsl:param name="owner" as="element()" />

      <xsl:variable name="uqnames" as="xs:string*"
         select="$owner/x:param/@name ! x:UQName-from-EQName-ignoring-default-ns(., parent::x:param)" />
      <xsl:for-each select="$uqnames[subsequence($uqnames, 1, position() - 1) = .][1]">
         <xsl:text expand-text="yes">Duplicate parameter name, {.}, used in {name($owner)}.</xsl:text>
      </xsl:for-each>
   </xsl:function>

   <!-- Returns an error string if the given element has duplicate x:param/@position -->
   <xsl:function name="local:param-dup-position-error-string" as="xs:string?">
      <xsl:param name="owner" as="element(x:call)" />

      <xsl:variable name="positions" as="xs:integer*"
         select="$owner/x:param/@position ! xs:integer(.)" />
      <xsl:for-each select="$positions[subsequence($positions, 1, position() - 1) = .][1]">
         <xsl:text expand-text="yes">Duplicate parameter position, {.}, used in {name($owner)}.</xsl:text>
      </xsl:for-each>
   </xsl:function>

</xsl:stylesheet>