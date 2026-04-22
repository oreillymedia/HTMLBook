<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:x="http://www.jenitennison.com/xslt/xspec"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                exclude-result-prefixes="#all"
                version="3.0">

   <!-- In result XML file, capture x:expect/@test or an "instance of" expression
      derived from x:expect/@result-type. -->
   <xsl:template name="x:report-test-attribute" as="node()+">
      <xsl:context-item as="element(x:expect)" use="required" />
      <xsl:param name="attribute-local-name" as="xs:string" select="'test'"/>

      <xsl:variable name="expect-with-attribute" as="element(x:expect)">
         <!-- Do not set xsl:copy/@copy-namespaces="no". @test may use namespace prefixes and/or the
            default namespace such as xs:QName('foo') -->
         <xsl:copy>
            <xsl:choose>
               <xsl:when test="$attribute-local-name eq 'test'">
                  <xsl:sequence select="@test"/>
               </xsl:when>
               <xsl:when test="$attribute-local-name eq 'result-type'">
                  <!--
                     Generate an attribute like the following, where the part after "instance of" is
                     the value of x:expect/@result-type.
                        result-type="$x:result instance of xs:double"
                  -->
                  <xsl:attribute name="{$attribute-local-name}" expand-text="yes">
                     <xsl:text>${x:xspec-name('result', .)} instance of {@result-type}</xsl:text>
                  </xsl:attribute>
               </xsl:when>
            </xsl:choose>
         </xsl:copy>
      </xsl:variable>

      <!-- Undeclare the default namespace in the wrapper element, because @test may use the default
         namespace such as xs:QName('foo'). -->
      <xsl:call-template name="x:wrap-node-constructors-and-undeclare-default-ns">
         <xsl:with-param name="wrapper-name" select="local-name() || '-test-wrap'" />
         <xsl:with-param name="node-constructors" as="node()+">
            <xsl:apply-templates select="$expect-with-attribute" mode="x:node-constructor" />
         </xsl:with-param>
      </xsl:call-template>
   </xsl:template>

</xsl:stylesheet>