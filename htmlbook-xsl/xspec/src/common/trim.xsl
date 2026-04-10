<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="#all" version="3.0"
	xmlns:x="http://www.jenitennison.com/xslt/xspec" xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

	<!--
		Removes leading whitespace
	-->
	<xsl:function as="xs:string" name="x:left-trim">
		<xsl:param as="xs:string" name="input" />

		<xsl:sequence select="replace($input, '^\s+', '')" />
	</xsl:function>

	<!--
		Removes trailing whitespace
	-->
	<xsl:function as="xs:string" name="x:right-trim">
		<xsl:param as="xs:string" name="input" />

		<xsl:sequence select="replace($input, '\s+$', '')" />
	</xsl:function>

	<!--
		Removes leading and trailing whitespace
	-->
	<xsl:function as="xs:string" name="x:trim">
		<xsl:param as="xs:string" name="input" />

		<xsl:sequence select="
				$input
				=> x:right-trim()
				=> x:left-trim()" />
	</xsl:function>

</xsl:stylesheet>
