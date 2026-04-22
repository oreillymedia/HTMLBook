<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="#all" version="3.0"
	xmlns:x="http://www.jenitennison.com/xslt/xspec" xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

	<!--
		Constructs URIQualifiedName from namespace URI and local name
	-->
	<xsl:function as="xs:string" name="x:UQName">
		<xsl:param as="xs:string" name="namespace-uri" />
		<xsl:param as="xs:string" name="local-name" />

		<xsl:sequence select="'Q{' || $namespace-uri || '}' || $local-name" />
	</xsl:function>

	<!--
		Returns URIQualifiedName constructed from known prefixes
	-->
	<xsl:function as="xs:string" name="x:known-UQName">
		<xsl:param as="xs:string" name="lexical-qname" />

		<xsl:variable as="xs:string" name="prefix" select="substring-before($lexical-qname, ':')" />
		<xsl:variable as="xs:string" name="local-name" select="substring-after($lexical-qname, ':')" />

		<xsl:variable as="xs:string" name="namespace">
			<xsl:choose>
				<xsl:when test="$prefix eq 'config'">
					<xsl:sequence select="'http://saxon.sf.net/ns/configuration'" />
				</xsl:when>
				<xsl:when test="$prefix eq 'deq'">
					<xsl:sequence select="$x:deq-namespace" />
				</xsl:when>
				<xsl:when test="$prefix eq 'err'">
					<xsl:sequence select="'http://www.w3.org/2005/xqt-errors'" />
				</xsl:when>
				<xsl:when test="$prefix eq 'impl'">
					<xsl:sequence select="'urn:x-xspec:compile:impl'" />
				</xsl:when>
				<xsl:when test="$prefix eq 'map'">
					<xsl:sequence select="'http://www.w3.org/2005/xpath-functions/map'" />
				</xsl:when>
				<xsl:when test="$prefix eq 'output'">
					<xsl:sequence select="'http://www.w3.org/2010/xslt-xquery-serialization'" />
				</xsl:when>
				<xsl:when test="$prefix eq 'p'">
					<xsl:sequence select="'http://www.w3.org/ns/xproc'" />
				</xsl:when>
				<xsl:when test="$prefix eq 'pf'">
					<xsl:sequence select="'http://www.jenitennison.com/xslt/xspec/xproc/steps/wrap-standard-functions'" />
				</xsl:when>
				<xsl:when test="$prefix eq 'rep'">
					<xsl:sequence select="$x:rep-namespace" />
				</xsl:when>
				<xsl:when test="$prefix eq 'saxon'">
					<xsl:sequence select="$x:saxon-namespace" />
				</xsl:when>
				<xsl:when test="$prefix eq 'sn'">
					<xsl:sequence select="$x:sn-namespace" />
				</xsl:when>
				<xsl:when test="$prefix eq 'svrl'">
					<xsl:sequence select="'http://purl.oclc.org/dsdl/svrl'" />
				</xsl:when>
				<xsl:when test="$prefix eq 'wrap'">
					<xsl:sequence select="$x:wrap-namespace" />
				</xsl:when>
				<xsl:when test="$prefix eq 'x'">
					<xsl:sequence select="$x:xspec-namespace" />
				</xsl:when>
				<xsl:when test="$prefix eq 'xs'">
					<xsl:sequence select="$x:xs-namespace" />
				</xsl:when>
				<xsl:when test="$prefix eq 'xsl'">
					<xsl:sequence select="$x:xsl-namespace" />
				</xsl:when>
			</xsl:choose>
		</xsl:variable>

		<xsl:sequence select="x:UQName($namespace, $local-name)" />
	</xsl:function>

	<!--
		Returns URIQualifiedName of QName
	-->
	<xsl:function as="xs:string" name="x:UQName-from-QName">
		<xsl:param as="xs:QName" name="qname" />

		<xsl:sequence
			select="$qname ! x:UQName(namespace-uri-from-QName(.), local-name-from-QName(.))" />
	</xsl:function>

	<!--
		URIQualifiedName version of fn:node-name()
	-->
	<xsl:function as="xs:string?" name="x:node-UQName">
		<xsl:param as="node()" name="node" />

		<xsl:sequence select="node-name($node) ! x:UQName-from-QName(.)" />
	</xsl:function>

</xsl:stylesheet>
