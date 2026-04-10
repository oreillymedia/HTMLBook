<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:x="http://www.jenitennison.com/xslt/xspec"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                exclude-result-prefixes="#all"
                version="3.0">

   <xsl:function name="x:combine" as="document-node(element(x:description))">
      <xsl:param name="specs" as="node()+" />

      <!-- Combine all the children of x:description into a single document so that the following
         transformation modes can handle them as a document. -->
      <xsl:variable name="specs-doc" as="document-node()">
         <xsl:document>
            <xsl:sequence select="$specs" />
         </xsl:document>
      </xsl:variable>

      <!-- Resolve x:like and @shared -->
      <xsl:variable name="unshared-doc" as="document-node()">
         <xsl:apply-templates select="$specs-doc" mode="x:unshare-scenarios" />
      </xsl:variable>

      <!-- Assign @id -->
      <xsl:variable name="doc-with-id" as="document-node()">
         <xsl:apply-templates select="$unshared-doc" mode="x:assign-id" />
      </xsl:variable>

      <!-- Force focus -->
      <xsl:variable name="doc-maybe-focus-enforced" as="document-node()">
         <xsl:apply-templates select="$doc-with-id" mode="x:force-focus" />
      </xsl:variable>

      <!-- Combine all the children of x:description into a single x:description -->
      <xsl:variable name="combined-doc" as="document-node(element(x:description))">
         <xsl:document>
            <xsl:for-each select="$initial-document/x:description">
               <!-- @name must not have a prefix. @inherit-namespaces must be no. Otherwise
                  the namespaces created for /x:description will pollute its descendants derived
                  from the other trees. -->
               <xsl:element name="{local-name()}" namespace="{namespace-uri()}"
                  inherit-namespaces="no">
                  <!-- Do not set all the attributes. Each imported x:description has its own set of
                     attributes. Set only the attributes that are truly global over all the XSpec
                     documents. -->

                  <!-- Global Schematron attributes.
                     These attributes are already absolute. (resolved by
                     ../schematron/schut-to-xspec.xsl) -->
                  <xsl:sequence select="@original-xspec | @schematron" />

                  <!-- Global XProc attributes. -->
                  <xsl:for-each select="@xproc">
                     <xsl:attribute name="{local-name()}" namespace="{namespace-uri()}"
                        select="resolve-uri(., base-uri())" />
                  </xsl:for-each>

                  <!-- Global XQuery attributes.
                     @query-at is handled by compile-xquery-tests.xsl -->
                  <xsl:sequence select="@query | @xquery-version" />

                  <!-- Global XSLT attributes.
                     @xslt-version can be set, because it has already been propagated from each
                     imported x:description to its descendants in mode="x:gather-specs". -->
                  <xsl:sequence select="@result-file-threshold | @threads | @xslt-version" />
                  <xsl:for-each select="@stylesheet">
                     <xsl:attribute name="{local-name()}" namespace="{namespace-uri()}"
                        select="resolve-uri(., base-uri())" />
                  </xsl:for-each>

                  <xsl:sequence select="$doc-maybe-focus-enforced" />
               </xsl:element>
            </xsl:for-each>
         </xsl:document>
      </xsl:variable>

      <!-- Return the combined XSpec document after checking it -->
      <xsl:apply-templates select="$combined-doc" mode="x:check-combined-doc" />
      <xsl:sequence select="$combined-doc" />
   </xsl:function>

   <!--
      Modes
   -->
   <xsl:include href="mode/assign-id.xsl" />
   <xsl:include href="mode/check-combined-doc.xsl" />
   <xsl:include href="mode/force-focus.xsl" />
   <xsl:include href="mode/generate-id.xsl" />
   <xsl:include href="mode/unshare-scenarios.xsl" />

</xsl:stylesheet>