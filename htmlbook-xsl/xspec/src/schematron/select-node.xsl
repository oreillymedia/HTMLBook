<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="#all" version="3.0"
	xmlns:sn="urn:x-xspec:schematron:select-node" xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
	xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

	<!--
		Evaluates the given XPath expression in the context of the given source node, with the given
		namespaces and in the given XSLT version compatibility mode.
	-->
	<xsl:function as="node()?" name="sn:select-node">
		<xsl:param as="node()" name="source-node" />
		<xsl:param as="xs:string" name="expression" />
		<xsl:param as="element(svrl:ns-prefix-in-attribute-values)*" name="namespaces" />
		<xsl:param as="xs:decimal" name="xslt-version" />

		<!--
			Generate the selector stylesheet
		-->
		<xsl:variable as="map(xs:string, item())" name="transform-options">
			<xsl:map>
				<xsl:map-entry key="'cache'" select="false()" />
				<xsl:map-entry key="'initial-template'" select="xs:QName('xsl:initial-template')" />
				<xsl:map-entry key="'stylesheet-location'" select="'generate-node-selector.xsl'" />
				<xsl:map-entry key="'template-params'">
					<xsl:map>
						<xsl:map-entry key="QName('', 'expression')" select="$expression" />
						<xsl:map-entry key="QName('', 'namespace-nodes')">
							<xsl:for-each select="$namespaces">
								<xsl:namespace name="{@prefix}" select="@uri" />
							</xsl:for-each>
						</xsl:map-entry>
						<xsl:map-entry key="QName('', 'xslt-version')" select="$xslt-version" />
					</xsl:map>
				</xsl:map-entry>
			</xsl:map>
		</xsl:variable>
		<xsl:variable as="document-node(element(xsl:stylesheet))" name="node-selector-doc"
			select="transform($transform-options)?output" />

		<!--
			Apply the generated selector to the source node
		-->
		<xsl:variable as="map(xs:string, item())" name="transform-options">
			<xsl:map>
				<xsl:map-entry key="'cache'" select="false()" />
				<xsl:map-entry key="'delivery-format'" select="'raw'" />
				<xsl:map-entry key="'source-node'" select="$source-node" />
				<xsl:map-entry key="'stylesheet-node'" select="$node-selector-doc" />
			</xsl:map>
		</xsl:variable>
		<xsl:sequence select="transform($transform-options)?output" />
	</xsl:function>

	<!--
		Returns the given sequence if it is one node, otherwise raises an error.
	-->
	<xsl:function as="node()" name="sn:node-or-error">
		<xsl:param as="item()*" name="maybe-node" />
		<xsl:param as="xs:string" name="expression" />
		<xsl:param as="xs:string" name="error-owner" />

		<xsl:choose>
			<xsl:when test="$maybe-node instance of node()">
				<xsl:sequence select="$maybe-node" />
			</xsl:when>

			<xsl:otherwise>
				<xsl:variable as="xs:string" name="description">
					<xsl:text expand-text="yes">ERROR in {$error-owner}: Expression {$expression} should point to one node.</xsl:text>
				</xsl:variable>
				<xsl:sequence select="error((), $description)" />
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>

</xsl:stylesheet>
