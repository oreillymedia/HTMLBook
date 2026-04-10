<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:x="http://www.jenitennison.com/xslt/xspec"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                exclude-result-prefixes="#all"
                version="3.0">

   <!--
      Generates <x:timestamp> creator.
   -->
   <xsl:template name="x:timestamp" as="text()+">
      <xsl:context-item use="absent" />

      <xsl:param name="event" as="xs:string" required="yes" />

      <!-- <x:timestamp> -->
      <xsl:text>element { </xsl:text>
      <xsl:value-of select="QName($x:xspec-namespace, 'timestamp') => x:QName-expression()" />
      <xsl:text> } {&#x0A;</xsl:text>

      <!-- @at must be evaluated at run time -->
      <xsl:text>attribute { QName('', 'at') } { </xsl:text>
      <xsl:value-of select="x:known-UQName('saxon:timestamp')" />
      <xsl:text>() },&#x0A;</xsl:text>

      <!-- @event -->
      <xsl:variable name="event-attribute" as="attribute(event)">
         <xsl:attribute name="event" select="$event" />
      </xsl:variable>
      <xsl:apply-templates select="$event-attribute" mode="x:node-constructor" />

      <!-- </x:timestamp> -->
      <xsl:text>}&#x0A;</xsl:text>
   </xsl:template>

</xsl:stylesheet>