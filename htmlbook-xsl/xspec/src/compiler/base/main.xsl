<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:x="http://www.jenitennison.com/xslt/xspec"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                exclude-result-prefixes="#all"
                version="3.0">

   <!--
      Global context item
   -->
   <!-- Actually, xsl:global-context-item/@as is "document-node(element(x:description))".
      "element(x:description)" is omitted in order to accept any source document and then reject it
      with a proper error message if it's broken. (xspec/xspec#522) -->
   <!-- Actually, xsl:global-context-item/@use is "required". It is downgraded to "optional" in
      order to be compatible with XSPEC_HOME/test/compile-xslt-tests.xspec. -->
   <xsl:global-context-item as="document-node()" use="optional" />

   <!--
      Global params
   -->

   <xsl:param name="force-focus" as="xs:string?" />
   <xsl:param name="is-external" as="xs:boolean"
      select="$initial-document/x:description/@run-as = 'external'" />
   <xsl:param name="measure-time" as="xs:boolean"
      select="$initial-document/x:description/@measure-time => x:yes-no-synonym(false())" />

   <!--
      Global variables
   -->

   <!-- The initial XSpec document (the source document of the whole transformation).
      Note that this initial document is different from the document node generated within the
      default mode template. The latter document is a restructured copy of the initial document.
      Usually the compiler templates should handle the restructured one, but in rare cases some of
      the compiler templates may need to access the initial document. -->
   <xsl:variable name="initial-document" as="document-node(element(x:description))" select="/" />

   <xsl:variable name="initial-document-actual-uri" as="xs:anyURI"
      select="x:document-actual-uri($initial-document)" />

   <!--
      Accumulators for scenario-level variable declarations (x:param and x:variable)
   -->

   <!-- Push and pop variable declaration elements based on node identity. Pending variable
      declaration elements are considered as if they did not exist. Treat <x:context> like a
      variable here because <x:context> causes the compiler to generate $x:context.
   -->
   <xsl:accumulator name="stacked-vardecls" as="element()*" initial-value="()">
      <xsl:accumulator-rule
         match="(x:scenario/x:param | x:scenario/x:variable | x:context)[x:reason-for-pending(.) => empty()]"
         select="
            (: Append this scenario-level variable declaration element :)
            $value, (self::x:param | self::x:variable | self::x:context)" />
      <xsl:accumulator-rule match="x:scenario" phase="end"
         select="
            (: Remove child variable declaration elements of this scenario :)
            $value except (child::x:param | child::x:variable | child::x:context)" />
   </xsl:accumulator>

   <!-- Push and pop distinct URIQualifiedName of variable declarations (x:param and x:variable).
      Pending variable declarations are considered as if they did not exist. -->
   <xsl:accumulator name="stacked-vardecls-distinct-uqnames" as="xs:string*" initial-value="()">
      <!-- Use x:distinct-strings-stable() instead of fn:distinct-values(). The x:compile-scenario
         template for XQuery requires the order to be stable. -->
      <!-- No need to explicitly exclude pending variable declarations. They're already excluded
         from the 'stacked-vardecls' accumulator. -->
      <xsl:accumulator-rule match="x:scenario/x:param | x:scenario/x:variable | x:context"
         select="
            x:distinct-strings-stable(
               accumulator-before('stacked-vardecls') ! x:variable-UQName(.)
            )" />
      <xsl:accumulator-rule match="x:scenario" phase="end"
         select="
            x:distinct-strings-stable(
               accumulator-after('stacked-vardecls') ! x:variable-UQName(.)
            )" />
   </xsl:accumulator>

   <!--
      mode="#default"
   -->
   <xsl:mode on-multiple-match="fail" on-no-match="fail" />

   <!-- Actually, xsl:template/@match is "document-node(element(x:description))".
      "element(x:description)" is omitted in order to accept any source document and then reject it
      with a proper error message if it's broken. (xspec/xspec#522) -->
   <xsl:template match="document-node()" as="node()+">
      <xsl:call-template name="x:perform-initial-check" />

      <!-- Resolve x:import and gather all the children of x:description -->
      <xsl:variable name="specs" as="node()+" select="x:resolve-import(x:description)" />

      <!-- Combine all the children of x:description into a single document so that the following
         language-specific transformation can handle them as a document. -->
      <xsl:variable name="combined-doc" as="document-node(element(x:description))"
         select="x:combine($specs)" />

      <!-- Switch the context to the x:description and dispatch it to the language-specific
         transformation (XSLT or XQuery) -->
      <xsl:for-each select="$combined-doc/x:description">
         <xsl:call-template name="x:main" />
      </xsl:for-each>
   </xsl:template>

   <!--
      Sub modules
   -->
   <xsl:include href="catch/enter-sut.xsl" />
   <xsl:include href="combine/combine.xsl" />
   <xsl:include href="compile/compile-child-scenarios-or-expects.xsl" />
   <xsl:include href="compile/compile-expect.xsl" />
   <xsl:include href="compile/compile-scenario.xsl" />
   <xsl:include href="declare-variable/declare-variable.xsl" />
   <xsl:include href="initial-check/perform-initial-check.xsl" />
   <xsl:include href="invoke-compiled/invoke-compiled-child-scenarios-or-expects.xsl" />
   <xsl:include href="invoke-compiled/threads.xsl" />
   <xsl:include href="report/report-test-attribute.xsl" />
   <xsl:include href="resolve-import/resolve-import.xsl" />
   <xsl:include href="util/compiler-eqname-utils.xsl" />
   <xsl:include href="util/compiler-misc-utils.xsl" />
   <xsl:include href="util/compiler-pending-utils.xsl" />

</xsl:stylesheet>