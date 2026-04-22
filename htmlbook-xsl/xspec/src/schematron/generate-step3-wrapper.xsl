<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="#all" version="3.0"
	xmlns:x="http://www.jenitennison.com/xslt/xspec" xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

	<!--
		This master stylesheet generates a wrapper stylesheet which imports the actual stylesheet
		of the Schematron Step 3 preprocessor.
		While generating the wrapper stylesheet, the following adjustments are made:
			* Transforms /x:description/x:param into /xsl:stylesheet/xsl:param.
		See ../../test/generate-step3-wrapper_*.xspec for examples.
	-->

	<!-- Absolute URI of the actual stylesheet of the Schematron Step 3 preprocessor.
		Empty sequence means the built-in preprocessor. -->
	<xsl:param as="xs:string?" name="ACTUAL-PREPROCESSOR-URI" />

	<!-- Import a compiler component and override it -->
	<xsl:import href="../compiler/base/resolve-import/resolve-import.xsl" />

	<xsl:include href="../common/common-utils.xsl" />
	<xsl:include href="../common/namespace-vars.xsl" />
	<xsl:include href="../common/trim.xsl" />
	<xsl:include href="../common/uqname-utils.xsl" />
	<xsl:include href="../common/uri-utils.xsl" />
	<xsl:include href="../common/user-content-utils.xsl" />
	<xsl:include href="../common/yes-no-utils.xsl" />
	<xsl:include href="../compiler/base/declare-variable/declare-variable.xsl" />
	<xsl:include href="../compiler/base/util/compiler-eqname-utils.xsl" />
	<xsl:include href="../compiler/base/util/compiler-misc-utils.xsl" />
	<xsl:include href="../compiler/base/util/compiler-pending-utils.xsl" />
	<xsl:include href="../compiler/xslt/declare-variable/declare-variable.xsl" />
	<xsl:include href="../compiler/xslt/declare-variable/selection-from-doc.xsl" />
	<xsl:include href="../compiler/xslt/node-constructor/node-constructor.xsl" />
	<xsl:include href="preprocessor.xsl" />

	<xsl:output indent="yes" />

	<xsl:mode on-multiple-match="fail" on-no-match="fail" />

	<xsl:template as="element(xsl:stylesheet)" match="document-node(element(x:description))">
		<xsl:apply-templates select="x:description" />
	</xsl:template>

	<xsl:template as="element(xsl:stylesheet)" match="x:description">
		<!-- Absolute URI of the stylesheet of the built-in Schematron Step 3 preprocessor -->
		<xsl:variable as="xs:anyURI" name="builtin-preprocessor-uri"
			select="$x:schematron-preprocessor?stylesheets?3" />

		<xsl:element name="xsl:stylesheet" namespace="{$x:xsl-namespace}">
			<xsl:attribute name="exclude-result-prefixes" select="'#all'" />
			<xsl:attribute name="version" select="x:xslt-version(.) => x:decimal-string()" />

			<!-- Import the stylesheet of the Schematron Step 3 preprocessor -->
			<xsl:element name="xsl:import" namespace="{$x:xsl-namespace}">
				<xsl:attribute name="href"
					select="($ACTUAL-PREPROCESSOR-URI, $builtin-preprocessor-uri)[1]" />
			</xsl:element>

			<xsl:variable as="element(x:description)" name="pseudo-description">
				<!--
					- Wrap x:param and x:variable in x:description so that they're recognized as
					  global ones.
					- Use x:xspec-name() for the element names just for cleanness.
				-->
				<xsl:element name="{x:xspec-name('description', .)}"
					namespace="{$x:xspec-namespace}">
					<!-- Define $x:xspec-uri in case global params or variables references it -->
					<xsl:element name="{x:xspec-name('variable', .)}" namespace="{$x:xspec-namespace}">
						<xsl:attribute name="as" select="x:known-UQName('xs:anyURI')" />
						<xsl:attribute name="name" select="x:known-UQName('x:xspec-uri')" />
						<xsl:value-of select="x:document-actual-uri(/)" />
					</xsl:element>
					
					<!-- Resolve x:import and gather only the user-provided global params and
						variables -->
					<xsl:sequence select="x:resolve-import(.)" />

					<!-- Always disable SchXslt metadata generation in SVRL -->
					<xsl:element name="{x:xspec-name('param', .)}" namespace="{$x:xspec-namespace}">
						<xsl:attribute name="as" select="x:known-UQName('xs:boolean')" />
						<xsl:attribute name="name" select="'schxslt.compile.metadata'" />
						<xsl:attribute name="select" select="'false()'" />
					</xsl:element>
				</xsl:element>
			</xsl:variable>

			<xsl:apply-templates mode="x:declare-variable" select="$pseudo-description/element()" />
		</xsl:element>
	</xsl:template>

	<!--
		mode="x:gather-specs"
		Override the imported mode in order to gather only x:description/(x:param | x:variable)
	-->

	<!-- Discard all except global params and variables -->
	<xsl:template as="empty-sequence()"
		match="x:description/node()[not(self::x:param | self::x:variable)]" mode="x:gather-specs" />

	<!-- Reject @static=yes, because it doesn't take effect.
		Making @static=yes take effect requires coordination with schut-to-xslt.xsl who invokes the
		wrapper stylesheet being generated here. Implementing it isn't worthwhile until requested
		seriously. -->
	<xsl:template as="empty-sequence()" match="x:param[x:yes-no-synonym(@static, false())]"
		mode="x:gather-specs">
		<!-- Normalize @name by applying the overridden templates -->
		<xsl:variable as="element(x:param)" name="param">
			<xsl:next-match />
		</xsl:variable>

		<!-- xsl:for-each is not for iteration but for simplifying XPath -->
		<xsl:for-each select="$param">
			<xsl:message terminate="yes">
				<xsl:call-template name="x:prefix-diag-message">
					<xsl:with-param name="message"
						select="'Enabling @static is not supported for Schematron.'" />
				</xsl:call-template>
			</xsl:message>
		</xsl:for-each>
	</xsl:template>

</xsl:stylesheet>
