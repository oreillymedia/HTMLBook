<?xml version="1.0" encoding="UTF-8"?>
<!-- Wrapper stylesheet for XSpec testing of htmlbook.xsl with Saxon HE 12.5.
     Imports htmlbook.xsl but overrides functions-exsl.xsl with functions-xslt2.xsl,
     which uses xsl:function syntax compatible with Saxon.
     Production uses htmlbook.xsl directly via lxml/libxslt, which supports functions-exsl.xsl.
     Both function files implement identical logic. See htmlbook.xsl for full explanation. -->
<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:h="http://www.w3.org/1999/xhtml"
                xmlns:htmlbook="https://github.com/oreillymedia/HTMLBook">

  <xsl:import href="../htmlbook.xsl"/>
  <xsl:include href="../functions-xslt2.xsl"/>

</xsl:stylesheet>
