<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="#all" version="3.0"
	xmlns:x="http://www.jenitennison.com/xslt/xspec" xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

	<!--
		Resolves URI (of an XML document) with the currently enabled catalog,
		working around an Apache XML Resolver bug
	-->
	<xsl:function as="xs:anyURI" name="x:resolve-xml-uri-with-catalog">
		<xsl:param as="xs:string" name="xml-uri" />

		<xsl:sequence select="
				$xml-uri
				=> doc()
				=> x:document-actual-uri()" />
	</xsl:function>

	<!--
		Returns the document actual URI (i.e. resolved with the currently enabled catalog),
		working around an Apache XML Resolver bug.
		
		This function is now just redirected to x:base-uri(). But this function is still here for
		the purpose of clarifying the caller's intention. i.e. The caller of this function wants to
		retrieve the document actual URI after catalog resolution (not some cryptic URI before
		catalog resolution).
	-->
	<xsl:function as="xs:anyURI" name="x:document-actual-uri">
		<xsl:param as="document-node()" name="doc" />

		<!-- https://sourceforge.net/p/saxon/mailman/message/36339785/
			"document-uri() returns the (absolutized) requested URI, while base-uri() returns
			the actual document location after catalog resolution." -->
		<xsl:sequence select="x:base-uri($doc)" />
	</xsl:function>

	<!--
		Performs fn:base-uri(), working around an Apache XML Resolver bug
	-->
	<xsl:function as="xs:anyURI" name="x:base-uri">
		<xsl:param as="node()" name="node" />

		<!-- Fix invalid URI such as 'file:C:/dir/file'
			https://issues.apache.org/jira/browse/XMLCOMMONS-24 -->
		<xsl:sequence select="
				$node
				=> base-uri()
				=> replace('^(file:)([^/])', '$1/$2')
				=> xs:anyURI()" />
	</xsl:function>

</xsl:stylesheet>
