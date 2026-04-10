<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:x="http://www.jenitennison.com/xslt/xspec"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                exclude-result-prefixes="#all"
                version="3.0">

   <!--
      Generates <x:timestamp> creator.
   -->
   <xsl:template name="x:timestamp" as="element(xsl:element)?">
      <xsl:context-item use="absent" />

      <xsl:param name="event" as="xs:string" required="yes" />

      <xsl:if test="$measure-time">
         <!-- <x:timestamp> -->
         <xsl:element name="xsl:element" namespace="{$x:xsl-namespace}">
            <xsl:attribute name="name" select="'timestamp'" />
            <xsl:attribute name="namespace" select="$x:xspec-namespace" />

            <!-- @at must be evaluated at run time -->
            <xsl:element name="xsl:attribute" namespace="{$x:xsl-namespace}">
               <xsl:attribute name="name" select="'at'" />
               <xsl:attribute name="namespace" />
               <xsl:attribute name="select" select="x:known-UQName('saxon:timestamp') || '()'" />
            </xsl:element>

            <!-- @event -->
            <xsl:variable name="event-attribute" as="attribute(event)">
               <xsl:attribute name="event" select="$event" />
            </xsl:variable>
            <xsl:apply-templates select="$event-attribute" mode="x:node-constructor" />

         <!-- </x:timestamp> -->
         </xsl:element>
      </xsl:if>
   </xsl:template>

</xsl:stylesheet>