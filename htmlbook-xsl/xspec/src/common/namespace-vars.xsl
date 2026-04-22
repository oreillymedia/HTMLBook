<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="#all" version="3.0"
	xmlns:x="http://www.jenitennison.com/xslt/xspec" xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

	<!--
		XSpec 'deq' namespace URI
	-->
	<xsl:variable as="xs:anyURI" name="x:deq-namespace"
		select="xs:anyURI('urn:x-xspec:common:deep-equal')" />

	<!--
		XSpec 'rep' namespace URI
	-->
	<xsl:variable as="xs:anyURI" name="x:rep-namespace"
		select="xs:anyURI('urn:x-xspec:common:report-sequence')" />

	<!--
		XSpec 'sn' namespace URI
	-->
	<xsl:variable as="xs:anyURI" name="x:sn-namespace"
		select="xs:anyURI('urn:x-xspec:schematron:select-node')" />

	<!--
		XSpec 'wrap' namespace URI
	-->
	<xsl:variable as="xs:anyURI" name="x:wrap-namespace" select="xs:anyURI('urn:x-xspec:common:wrap')" />

	<!--
		Saxon 'saxon' namespace URI
	-->
	<xsl:variable as="xs:anyURI" name="x:saxon-namespace" select="xs:anyURI('http://saxon.sf.net/')" />

	<!--
		Standard 'xs' namespace URI
	-->
	<xsl:variable as="xs:anyURI" name="x:xs-namespace"
		select="xs:anyURI('http://www.w3.org/2001/XMLSchema')" />

	<!--
		Standard 'xsl' namespace URI
	-->
	<xsl:variable as="xs:anyURI" name="x:xsl-namespace"
		select="xs:anyURI('http://www.w3.org/1999/XSL/Transform')" />

</xsl:stylesheet>
