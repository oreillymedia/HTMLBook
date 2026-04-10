<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:local="urn:x-xspec:compiler:base:combine:mode:check-combined-doc:local"
                xmlns:x="http://www.jenitennison.com/xslt/xspec"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                exclude-result-prefixes="#all"
                version="3.0">

   <!--
      mode="x:check-combined-doc"
      This mode checks a combined XSpec document.
   -->
   <xsl:mode name="x:check-combined-doc" on-multiple-match="fail" on-no-match="shallow-skip" />

   <xsl:template match="x:call" as="empty-sequence()" mode="x:check-combined-doc">
      <xsl:call-template name="local:detect-call-as-variable-run-as-external" />
      <xsl:apply-templates mode="#current"/>
   </xsl:template>

   <xsl:template match="x:param" as="empty-sequence()" mode="x:check-combined-doc">
      <xsl:call-template name="local:detect-reserved-vardecl-name" />

      <xsl:if test="
            parent::x:description or parent::x:scenario
            (: For now, do not check function-param and template-param. :)">
         <xsl:call-template name="local:detect-conflicting-vardecl" />
      </xsl:if>

      <!-- mode="x:declare-variable" is not aware of $is-external. That's why checking x:param
         against $is-external is performed here rather than in mode="x:declare-variable". -->
      <xsl:choose>
         <xsl:when test="parent::x:description">
            <xsl:call-template name="local:detect-static-description-param-run-as-import" />
         </xsl:when>
         <xsl:when test="parent::x:scenario">
            <xsl:call-template name="local:detect-scenario-param-run-as-import" />
         </xsl:when>
      </xsl:choose>
   </xsl:template>

   <xsl:template match="x:variable" as="empty-sequence()" mode="x:check-combined-doc">
      <xsl:call-template name="local:detect-reserved-vardecl-name" />
      <xsl:call-template name="local:detect-conflicting-vardecl" />
   </xsl:template>

   <!--
      Local templates
   -->

   <!-- Reject user-defined variable declaration with names in XSpec namespace. -->
   <xsl:template name="local:detect-reserved-vardecl-name" as="empty-sequence()">
      <!-- Context item must be x:param or x:variable -->
      <xsl:context-item as="element()" use="required" />

      <xsl:if test="@name">
         <xsl:variable name="qname" as="xs:QName"
            select="x:resolve-EQName-ignoring-default-ns(@name, .)" />

         <xsl:if test="namespace-uri-from-QName($qname) eq $x:xspec-namespace">
            <xsl:choose>
               <xsl:when test="
                     self::x:variable
                     [$is-external]
                     [local-name-from-QName($qname) eq 'saxon-config']">
                  <!-- Allow it -->
                  <!--
                     TODO: Consider replacing this abusive <xsl:variable> with a dedicated element
                     defined in the XSpec schema, like <x:config type="saxon" href="..." />. A
                     vendor-independent element name would be better than a vendor-specific element
                     name like <x:saxon-config>; a vendor-specific attribute value seems more
                     appropriate.
                  -->
               </xsl:when>

               <xsl:when test="
                  self::x:variable
                  [local-name-from-QName($qname) eq 'context']/
                  ancestor::x:description[exists(@query)][exists(@schematron)][exists(@original-xspec)]">
                  <!-- Allow it in a test for XQuery that was generated from a test
                     for a Schematron schema that targets the XQS implementation of
                     Schematron. -->
               </xsl:when>

               <xsl:otherwise>
                  <!-- Reject it -->
                  <xsl:message terminate="yes">
                     <xsl:call-template name="x:prefix-diag-message">
                        <xsl:with-param name="message">
                           <xsl:text expand-text="yes">Name {@name} must not use the XSpec namespace.</xsl:text>
                        </xsl:with-param>
                     </xsl:call-template>
                  </xsl:message>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:if>
      </xsl:if>
   </xsl:template>

   <!-- Reject x:call[@call-as='variable'] if @run-as=external. -->
   <xsl:template name="local:detect-call-as-variable-run-as-external" as="empty-sequence()">
      <xsl:context-item as="element(x:call)" use="required" />

      <xsl:if test="$is-external and @call-as eq 'variable'">
         <xsl:message terminate="yes">
            <xsl:call-template name="x:prefix-diag-message">
               <xsl:with-param name="message">
                  <xsl:text expand-text="yes">Calling a variable stored in a function is not supported when /{$initial-document/x:description => name()} has @run-as='external'.</xsl:text>
               </xsl:with-param>
            </xsl:call-template>
         </xsl:message>
      </xsl:if>
   </xsl:template>

   <!-- Reject static /x:description/x:param if not @run-as=external. -->
   <xsl:template name="local:detect-static-description-param-run-as-import" as="empty-sequence()">
      <!-- Context item must be x:param[parent::x:description] -->
      <xsl:context-item as="element(x:param)" use="required" />

      <xsl:if test="not($is-external) and x:yes-no-synonym(@static, false())">
         <xsl:message terminate="yes">
            <xsl:call-template name="x:prefix-diag-message">
               <xsl:with-param name="message">
                  <xsl:text expand-text="yes">Enabling @static is supported only when /{$initial-document/x:description => name()} has @run-as='external'.</xsl:text>
               </xsl:with-param>
            </xsl:call-template>
         </xsl:message>
      </xsl:if>
   </xsl:template>

   <!-- Reject //x:scenario/x:param if not @run-as=external. -->
   <xsl:template name="local:detect-scenario-param-run-as-import" as="empty-sequence()">
      <!-- Context item must be x:param[parent::x:scenario] -->
      <xsl:context-item as="element(x:param)" use="required" />

      <xsl:if test="not($is-external)">
         <xsl:message terminate="yes">
            <xsl:call-template name="x:prefix-diag-message">
               <xsl:with-param name="message">
                  <!-- /src/schematron/schut-to-xspec.xsl removes the name prefix from x:description.
                     That's why URIQualifiedName is used. -->
                  <xsl:text expand-text="yes">{name(parent::x:scenario)} has {name()}, which is supported only when /{/x:description => x:node-UQName()} has @run-as='external'.</xsl:text>
               </xsl:with-param>
            </xsl:call-template>
         </xsl:message>
      </xsl:if>
   </xsl:template>

   <!-- Reject variable declarations (x:param and x:variable) conflicting with another one. -->
   <xsl:template name="local:detect-conflicting-vardecl" as="empty-sequence()">
      <!-- Context item must be x:param[parent::x:description or parent::x:scenario] or x:variable -->
      <xsl:context-item as="element()" use="required" />

      <!-- URIQualifiedName of the current variable declaration -->
      <xsl:variable name="uqname" as="xs:string" select="x:variable-UQName(.)" />

      <!-- Description-level variable declarations that are visible from the current variable
         declaration element -->
      <xsl:variable name="visible-description-vardecls" as="element()*"
         select="/x:description/(x:param | x:variable) except ." />

      <!-- All the visible variable declarations (description-level + scenario level) -->
      <xsl:variable name="visible-vardecls" as="element()*" select="
            $visible-description-vardecls
            | accumulator-before('stacked-vardecls')
            | (preceding-sibling::x:param | preceding-sibling::x:variable)" />

      <!-- Variable declarations that the current one is allowed to override -->
      <xsl:variable name="overridable-vardecls" as="element()*" select="
            $visible-vardecls[node-name() eq node-name(current())]

            (: Description-level variable declaration are not allowed to override another
               description-level one :)
            except $visible-description-vardecls[current()[parent::x:description]]" />

      <!-- One of the variable declarations with which the current one conflicts -->
      <xsl:variable name="conflicts-with" as="element()?" select="
            ($visible-vardecls except $overridable-vardecls)
            [x:variable-UQName(.) eq $uqname][1]" />

      <!-- Terminate if any -->
      <xsl:if test="$conflicts-with">
         <xsl:message terminate="yes">
            <xsl:call-template name="x:prefix-diag-message">
               <xsl:with-param name="message">
                  <xsl:for-each select="$conflicts-with">
                     <xsl:text expand-text="yes">Name conflicts with {name()} (named {@name})</xsl:text>
                  </xsl:for-each>
               </xsl:with-param>
            </xsl:call-template>
         </xsl:message>
      </xsl:if>
   </xsl:template>

</xsl:stylesheet>
