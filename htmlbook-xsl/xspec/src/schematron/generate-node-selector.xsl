<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="#all" version="3.0"
	xmlns:x="http://www.jenitennison.com/xslt/xspec" xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

	<xsl:include href="../common/namespace-vars.xsl" />

	<xsl:global-context-item use="absent" />

	<xsl:output indent="yes" />

	<xsl:mode on-multiple-match="fail" on-no-match="fail" />

	<!--
		Generates a node selector stylesheet to serve select-node.xsl.
		See ../../test/generate-node-selector.xspec for examples.
	-->
	<xsl:template as="document-node(element(xsl:stylesheet))" name="xsl:initial-template">
		<xsl:context-item use="absent" />

		<xsl:param as="xs:string" name="expression" required="yes" />
		<xsl:param as="namespace-node()*" name="namespace-nodes" />
		<xsl:param as="xs:decimal" name="xslt-version" required="yes" />

		<xsl:document>
			<xsl:element name="xsl:stylesheet" namespace="{$x:xsl-namespace}">
				<xsl:attribute name="exclude-result-prefixes" select="'#all'" />
				<xsl:sequence select="doc('')/xsl:*/@version => exactly-one()" />

				<xsl:element name="xsl:mode" namespace="{$x:xsl-namespace}">
					<xsl:attribute name="on-multiple-match" select="'fail'" />
					<xsl:attribute name="on-no-match" select="'fail'" />
				</xsl:element>

				<xsl:element name="xsl:template" namespace="{$x:xsl-namespace}">
					<xsl:attribute name="as" select="'node()?'" />
					<xsl:attribute name="match" select="'attribute() | document-node() | node()'" />

					<xsl:element name="xsl:sequence" namespace="{$x:xsl-namespace}">
						<xsl:sequence select="$namespace-nodes" />

						<xsl:attribute name="select" select="$expression" />
						<xsl:attribute name="version" select="$xslt-version" />
					</xsl:element>
				</xsl:element>
			</xsl:element>
		</xsl:document>
	</xsl:template>

</xsl:stylesheet>
