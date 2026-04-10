<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                exclude-result-prefixes="#all"
                version="3.0">
   <!-- the tested stylesheet -->
   <xsl:import href="file:/Users/ghyman/Documents/Resources/orm_repos/HTMLBook/htmlbook-xsl/epub.xsl"/>
   <!-- XSpec library modules providing tools -->
   <xsl:include href="file:/Users/ghyman/Documents/Resources/orm_repos/HTMLBook/htmlbook-xsl/xspec/src/common/runtime-utils.xsl"/>
   <xsl:variable name="Q{http://www.jenitennison.com/xslt/xspec}stylesheet-uri"
                 as="Q{http://www.w3.org/2001/XMLSchema}anyURI">file:/Users/ghyman/Documents/Resources/orm_repos/HTMLBook/htmlbook-xsl/epub.xsl</xsl:variable>
   <xsl:variable name="Q{http://www.jenitennison.com/xslt/xspec}xspec-uri"
                 as="Q{http://www.w3.org/2001/XMLSchema}anyURI">file:/Users/ghyman/Documents/Resources/orm_repos/HTMLBook/htmlbook-xsl/xspec/epub.xspec</xsl:variable>
   <xsl:variable name="Q{http://www.jenitennison.com/xslt/xspec}is-external"
                 as="Q{http://www.w3.org/2001/XMLSchema}boolean"
                 select="false()"/>
   <xsl:variable name="Q{urn:x-xspec:compile:impl}thread-aware"
                 as="Q{http://www.w3.org/2001/XMLSchema}boolean"
                 select="(system-property('Q{http://www.w3.org/1999/XSL/Transform}product-name') eq 'SAXON') and starts-with(system-property('Q{http://www.w3.org/1999/XSL/Transform}product-version'), 'EE ')"
                 static="yes"/>
   <xsl:variable name="Q{urn:x-xspec:compile:impl}logical-processor-count"
                 as="Q{http://www.w3.org/2001/XMLSchema}integer"
                 use-when="$Q{urn:x-xspec:compile:impl}thread-aware"
                 select="Q{java:java.lang.Runtime}getRuntime() =&gt; Q{java:java.lang.Runtime}availableProcessors()"/>
   <xsl:variable name="Q{urn:x-xspec:compile:impl}thread-count"
                 as="Q{http://www.w3.org/2001/XMLSchema}integer"
                 select="1"
                 use-when="$Q{urn:x-xspec:compile:impl}thread-aware =&gt; not()"/>
   <!-- the main template to run the suite -->
   <xsl:template name="Q{http://www.jenitennison.com/xslt/xspec}main"
                 as="empty-sequence()">
      <xsl:context-item use="absent"/>
      <!-- info message -->
      <xsl:message>
         <xsl:text>Testing with </xsl:text>
         <xsl:value-of select="system-property('Q{http://www.w3.org/1999/XSL/Transform}product-name')"/>
         <xsl:text> </xsl:text>
         <xsl:value-of select="system-property('Q{http://www.w3.org/1999/XSL/Transform}product-version')"/>
      </xsl:message>
      <!-- set up the result document (the report) -->
      <xsl:result-document format="Q{{http://www.jenitennison.com/xslt/xspec}}xml-report-serialization-parameters">
         <xsl:element name="report" namespace="http://www.jenitennison.com/xslt/xspec">
            <xsl:attribute name="xspec" namespace="">file:/Users/ghyman/Documents/Resources/orm_repos/HTMLBook/htmlbook-xsl/xspec/epub.xspec</xsl:attribute>
            <xsl:attribute name="stylesheet" namespace="">file:/Users/ghyman/Documents/Resources/orm_repos/HTMLBook/htmlbook-xsl/epub.xsl</xsl:attribute>
            <xsl:attribute name="date" namespace="" select="current-dateTime()"/>
            <!-- invoke each compiled top-level x:scenario -->
            <xsl:for-each select="1 to 1">
               <xsl:choose>
                  <xsl:when test=". eq 1">
                     <xsl:call-template name="Q{http://www.jenitennison.com/xslt/xspec}scenario1"/>
                  </xsl:when>
                  <xsl:otherwise>
                     <xsl:message terminate="yes">ERROR: Unhandled scenario invocation</xsl:message>
                  </xsl:otherwise>
               </xsl:choose>
            </xsl:for-each>
         </xsl:element>
      </xsl:result-document>
   </xsl:template>
   <xsl:template name="Q{http://www.jenitennison.com/xslt/xspec}scenario1"
                 as="element(Q{http://www.jenitennison.com/xslt/xspec}scenario)">
      <xsl:context-item use="absent"/>
      <xsl:message>PENDING: (We received an error when trying to run this scenario. We were using the Saxon JAR file version SAXON HE 9.5.1.2 and the script from https://github.com/xspec/xspec.) When a data-type attribute is matched</xsl:message>
      <xsl:element name="scenario" namespace="http://www.jenitennison.com/xslt/xspec">
         <xsl:attribute name="id" namespace="">scenario1</xsl:attribute>
         <xsl:attribute name="xspec" namespace="">file:/Users/ghyman/Documents/Resources/orm_repos/HTMLBook/htmlbook-xsl/xspec/epub.xspec</xsl:attribute>
         <xsl:attribute name="pending" namespace="">We received an  error when trying to run this scenario. We were using the Saxon JAR file version SAXON HE 9.5.1.2 and the script from https://github.com/xspec/xspec.</xsl:attribute>
         <xsl:element name="label" namespace="http://www.jenitennison.com/xslt/xspec">
            <xsl:text>When a data-type attribute is matched</xsl:text>
         </xsl:element>
         <xsl:element name="input-wrap" namespace="">
            <xsl:element name="x:context" namespace="http://www.jenitennison.com/xslt/xspec">
               <xsl:namespace name="">http://www.w3.org/1999/xhtml</xsl:namespace>
               <xsl:namespace name="dc">http://purl.org/dc/elements/1.1/</xsl:namespace>
               <xsl:namespace name="dcterms">http://purl.org/dc/terms/</xsl:namespace>
               <xsl:namespace name="e">http://github.com/oreillymedia/epubrenderer</xsl:namespace>
               <xsl:namespace name="epub">http://www.idpf.org/2007/ops</xsl:namespace>
               <xsl:namespace name="functx">http://www.functx.com</xsl:namespace>
               <xsl:namespace name="h">http://www.w3.org/1999/xhtml</xsl:namespace>
               <xsl:namespace name="ncx">http://www.daisy.org/z3986/2005/ncx/</xsl:namespace>
               <xsl:namespace name="opf">http://www.idpf.org/2007/opf</xsl:namespace>
               <xsl:attribute name="select" namespace="">(/h:aside)[1]</xsl:attribute>
               <xsl:element name="aside" namespace="http://www.w3.org/1999/xhtml">
                  <xsl:namespace name="dc">http://purl.org/dc/elements/1.1/</xsl:namespace>
                  <xsl:namespace name="dcterms">http://purl.org/dc/terms/</xsl:namespace>
                  <xsl:namespace name="e">http://github.com/oreillymedia/epubrenderer</xsl:namespace>
                  <xsl:namespace name="epub">http://www.idpf.org/2007/ops</xsl:namespace>
                  <xsl:namespace name="functx">http://www.functx.com</xsl:namespace>
                  <xsl:namespace name="h">http://www.w3.org/1999/xhtml</xsl:namespace>
                  <xsl:namespace name="ncx">http://www.daisy.org/z3986/2005/ncx/</xsl:namespace>
                  <xsl:namespace name="opf">http://www.idpf.org/2007/opf</xsl:namespace>
                  <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                  <xsl:attribute xmlns="http://www.w3.org/1999/xhtml"
                                 xmlns:dc="http://purl.org/dc/elements/1.1/"
                                 xmlns:dcterms="http://purl.org/dc/terms/"
                                 xmlns:e="http://github.com/oreillymedia/epubrenderer"
                                 xmlns:epub="http://www.idpf.org/2007/ops"
                                 xmlns:functx="http://www.functx.com"
                                 xmlns:h="http://www.w3.org/1999/xhtml"
                                 xmlns:ncx="http://www.daisy.org/z3986/2005/ncx/"
                                 xmlns:opf="http://www.idpf.org/2007/opf"
                                 xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                 name="data-type"
                                 namespace=""
                                 select="'', ''"
                                 separator="sidebar"/>
                  <xsl:element name="h5" namespace="http://www.w3.org/1999/xhtml">
                     <xsl:namespace name="dc">http://purl.org/dc/elements/1.1/</xsl:namespace>
                     <xsl:namespace name="dcterms">http://purl.org/dc/terms/</xsl:namespace>
                     <xsl:namespace name="e">http://github.com/oreillymedia/epubrenderer</xsl:namespace>
                     <xsl:namespace name="epub">http://www.idpf.org/2007/ops</xsl:namespace>
                     <xsl:namespace name="functx">http://www.functx.com</xsl:namespace>
                     <xsl:namespace name="h">http://www.w3.org/1999/xhtml</xsl:namespace>
                     <xsl:namespace name="ncx">http://www.daisy.org/z3986/2005/ncx/</xsl:namespace>
                     <xsl:namespace name="opf">http://www.idpf.org/2007/opf</xsl:namespace>
                     <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                     <xsl:text>Sidebar title</xsl:text>
                  </xsl:element>
                  <xsl:element name="p" namespace="http://www.w3.org/1999/xhtml">
                     <xsl:namespace name="dc">http://purl.org/dc/elements/1.1/</xsl:namespace>
                     <xsl:namespace name="dcterms">http://purl.org/dc/terms/</xsl:namespace>
                     <xsl:namespace name="e">http://github.com/oreillymedia/epubrenderer</xsl:namespace>
                     <xsl:namespace name="epub">http://www.idpf.org/2007/ops</xsl:namespace>
                     <xsl:namespace name="functx">http://www.functx.com</xsl:namespace>
                     <xsl:namespace name="h">http://www.w3.org/1999/xhtml</xsl:namespace>
                     <xsl:namespace name="ncx">http://www.daisy.org/z3986/2005/ncx/</xsl:namespace>
                     <xsl:namespace name="opf">http://www.idpf.org/2007/opf</xsl:namespace>
                     <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                     <xsl:text>Some text</xsl:text>
                  </xsl:element>
               </xsl:element>
            </xsl:element>
         </xsl:element>
         <xsl:call-template name="Q{http://www.jenitennison.com/xslt/xspec}scenario1-expect1"/>
      </xsl:element>
   </xsl:template>
   <xsl:template name="Q{http://www.jenitennison.com/xslt/xspec}scenario1-expect1"
                 as="element(Q{http://www.jenitennison.com/xslt/xspec}test)">
      <xsl:context-item use="absent"/>
      <xsl:message>PENDING: (We received an error when trying to run this scenario. We were using the Saxon JAR file version SAXON HE 9.5.1.2 and the script from https://github.com/xspec/xspec.) It should be propagated to output as is, and also in a epub:type attribute (if part of the EPUB SSV)</xsl:message>
      <xsl:element name="test" namespace="http://www.jenitennison.com/xslt/xspec">
         <xsl:attribute name="id" namespace="">scenario1-expect1</xsl:attribute>
         <xsl:attribute name="pending" namespace="">We received an  error when trying to run this scenario. We were using the Saxon JAR file version SAXON HE 9.5.1.2 and the script from https://github.com/xspec/xspec.</xsl:attribute>
         <xsl:element name="label" namespace="http://www.jenitennison.com/xslt/xspec">
            <xsl:text>It should be propagated to output as is, and also in a epub:type attribute (if part of the EPUB SSV)</xsl:text>
         </xsl:element>
      </xsl:element>
   </xsl:template>
</xsl:stylesheet>
