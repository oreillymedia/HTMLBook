<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="#all" version="3.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

	<!--
		This stylesheet is included in the compiled test runner and also serves as a master file on
		Oxygen.
	-->

	<xsl:include href="common-utils.xsl" />
	<xsl:include href="deep-equal.xsl" />
	<xsl:include href="namespace-vars.xsl" />
	<xsl:include href="report-sequence.xsl" />
	<xsl:include href="uqname-utils.xsl" />
	<xsl:include href="wrap.xsl" />
	<xsl:include href="xml-report-serialization-parameters.xsl" />

</xsl:stylesheet>
