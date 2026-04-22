<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:local="urn:x-xspec:compiler:base:resolve-import:gather:gather-specs:local"
                xmlns:p="http://www.w3.org/ns/xproc"
                xmlns:x="http://www.jenitennison.com/xslt/xspec"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                exclude-result-prefixes="#all"
                version="3.0">

   <!--
      mode="x:gather-specs"

      This mode makes each spec less context-dependent by performing these transformations:

      * Discard x:import. (x:import must be resolved before applying this mode.)
      * Copy @xslt-version from x:description to descendant x:scenario (only when @xslt-version
        has not been set by a previous process).
      * Add @xspec (and @original-xspec if @xspec has already been set by a previous process) to
        each scenario. The goal is to record the absolute URI of originating .xspec file.
      * Resolve x:*/@href and x:helper/(@query-at|@stylesheet) into absolute URI.
      * Discard whitespace-only text node in non user-content unless it's in x:label.
      * Remove leading and trailing whitespace from names.
      * (See mode="local:gather-user-content" for user-content.)
   -->
   <xsl:mode name="x:gather-specs" on-multiple-match="fail" on-no-match="shallow-copy" />

   <!-- Dispatch user-content to its dedicated mode. This must be done in the highest priority. -->
   <xsl:template match="node()[x:is-user-content(.)]" as="node()?" mode="x:gather-specs" priority="1">
      <xsl:apply-templates select="." mode="local:gather-user-content" />
   </xsl:template>

   <!-- This mode always starts from this template -->
   <xsl:template match="x:description" as="node()*" mode="x:gather-specs">
      <xsl:apply-templates mode="#current">
         <xsl:with-param name="xslt-version"   tunnel="yes" select="x:xslt-version(.)"/>
         <xsl:with-param name="preserve-space" tunnel="yes" select="x:parse-preserve-space(.)" />
         <xsl:with-param name="xspec-module-uri" tunnel="yes" select="x:document-actual-uri(/)" />
      </xsl:apply-templates>
   </xsl:template>

   <xsl:template match="x:import" as="empty-sequence()" mode="x:gather-specs" />

   <xsl:template match="x:scenario" as="element(x:scenario)" mode="x:gather-specs">
      <xsl:param name="xslt-version" as="xs:decimal" tunnel="yes" required="yes"/>
      <xsl:param name="xspec-module-uri" as="xs:anyURI" tunnel="yes" required="yes" />

      <xsl:copy>
         <!-- Construct @xslt-version before applying templates to attributes so that the existing
            one takes precedence -->
         <xsl:attribute name="xslt-version" select="$xslt-version" />

         <xsl:attribute name="xspec" select="$xspec-module-uri" />

         <xsl:apply-templates select="attribute() | node()" mode="#current" />
      </xsl:copy>
   </xsl:template>

   <xsl:template match="x:scenario/@xspec" as="attribute(original-xspec)">
      <xsl:for-each select="parent::element()/@original-xspec">
         <xsl:message terminate="yes">
            <xsl:call-template name="x:prefix-diag-message">
               <xsl:with-param name="message">
                  <xsl:text expand-text="yes">Already has @{name()}</xsl:text>
               </xsl:with-param>
            </xsl:call-template>
         </xsl:message>
      </xsl:for-each>

      <xsl:attribute name="original-xspec" select="." />
   </xsl:template>

   <xsl:template match="text()[normalize-space() => not()]" as="text()?" mode="x:gather-specs">
      <xsl:if test="parent::x:label">
         <!-- FYI: Preserve whitespace in x:label and @label. -->
         <xsl:sequence select="." />
      </xsl:if>
   </xsl:template>

   <!-- TODO: Perhaps, @query-at hint should not always be resolved???
      (See https://github.com/xspec/xspec/blob/6d2442dc938cb233b815c4cc2b43f4eb2a075ccb/src/compiler/generate-query-tests.xsl#L41) -->
   <!-- The exception for p:document/@href is because it will be evaluated in XProc, not XSLT. -->
   <xsl:template
      match="@href[not(parent::p:document)] | (@query-at | @stylesheet)[parent::x:helper]"
      as="attribute()"
      mode="x:gather-specs">
      <xsl:attribute name="{local-name()}" namespace="{namespace-uri()}"
         select="resolve-uri(., x:base-uri(.))" />
   </xsl:template>

   <xsl:template match="@as | @function | @mode | @name | @port | @template" as="attribute()"
      mode="x:gather-specs">
      <xsl:attribute name="{local-name()}" namespace="{namespace-uri()}" select="x:trim(.)" />
   </xsl:template>

   <!--
      Local templates
   -->

   <!--
      mode="local:gather-user-content"

      This mode works as a part of mode="x:gather-specs" and handles user-content by performing
      these transformations:

      * Error on obsolete x:space.
      * Discard @x:expand-text.
      * Discard whitespace-only text node unless otherwise specified by an ancestor.
      * Wrap text node in x:text resolving @expand-text and @x:expand-text specified by an ancestor.

      Once you enter this mode, you never go back to mode="x:gather-specs".
   -->
   <xsl:mode name="local:gather-user-content" on-multiple-match="fail" on-no-match="shallow-copy" />

   <!-- x:space has been replaced with x:text -->
   <xsl:template match="x:space" as="empty-sequence()" mode="local:gather-user-content">
      <xsl:message terminate="yes">
         <xsl:call-template name="x:prefix-diag-message">
            <xsl:with-param name="message">
               <!-- Use x:xspec-name() for displaying the x:text element name with the prefix preferred by
                  the user -->
               <xsl:text expand-text="yes">{name()} is obsolete. Use {x:xspec-name('text', .)} instead.</xsl:text>
            </xsl:with-param>
         </xsl:call-template>
      </xsl:message>
   </xsl:template>

   <xsl:template match="@x:expand-text" as="empty-sequence()" mode="local:gather-user-content" />

   <xsl:template match="x:text" as="element(x:text)?" mode="local:gather-user-content">
      <!-- Unwrap -->
      <xsl:apply-templates mode="#current" />
   </xsl:template>

   <xsl:template match="text()" as="element(x:text)?" mode="local:gather-user-content">
      <xsl:param name="preserve-space" as="xs:QName*" required="yes" tunnel="yes" />

      <xsl:if test="normalize-space()
         or x:is-ws-only-text-node-significant(., $preserve-space)">
         <!-- Use x:xspec-name() for the element name so that the namespace for the name of the
            created element does not pollute the namespaces copied for TVT.
            Unfortunately the parent element does not always have the XSpec namespace. So, search
            the ancestor elements for the XSpec namespace that will be less likely to be intrusive. -->
         <xsl:element name="{
            x:xspec-name(
               'text',
               ancestor::element()[x:copy-of-namespaces(.) = $x:xspec-namespace][1]
            )}"
            namespace="{$x:xspec-namespace}">
            <xsl:variable name="expand-text" as="attribute()?"
               select="
                  ancestor::*[if (self::x:*)
                              then @expand-text
                              else @x:expand-text][1]
                  /@*[if (parent::x:*)
                      then self::attribute(expand-text)
                      else self::attribute(x:expand-text)]" />
            <xsl:if test="$expand-text">
               <xsl:if test="x:yes-no-synonym($expand-text)">
                  <!-- TVT may use namespace prefixes and/or the default namespace such as
                     xs:QName('foo') -->
                  <xsl:sequence select="parent::element() => x:copy-of-namespaces()" />
               </xsl:if>

               <xsl:attribute name="expand-text" select="$expand-text"/>
            </xsl:if>

            <xsl:sequence select="." />
         </xsl:element>
      </xsl:if>
   </xsl:template>

</xsl:stylesheet>