<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="#all" version="3.0"
	xmlns:local="urn:x-xspec:schematron:schut-to-xslt:local"
	xmlns:x="http://www.jenitennison.com/xslt/xspec" xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

	<!--
		$STEP?-PREPROCESSOR-DOC is for ../../bin/xspec.* who can pass a document node as a
		stylesheet parameter but can not handle URI natively.
		Those who can pass a URI as a stylesheet parameter natively will probably prefer
		$STEP?-PREPROCESSOR-URI.
	-->
	<xsl:param as="document-node()?" name="STEP1-PREPROCESSOR-DOC" />
	<xsl:param as="document-node()?" name="STEP2-PREPROCESSOR-DOC" />
	<xsl:param as="document-node()?" name="STEP3-PREPROCESSOR-DOC" />

	<xsl:param as="xs:string" name="STEP1-PREPROCESSOR-URI"
		select="$x:schematron-preprocessor?stylesheets?1" />
	<xsl:param as="xs:string" name="STEP2-PREPROCESSOR-URI"
		select="$x:schematron-preprocessor?stylesheets?2" />
	<xsl:param as="xs:string?" name="STEP3-PREPROCESSOR-URI"
		select="base-uri($STEP3-PREPROCESSOR-DOC)" />

	<xsl:param as="xs:boolean" name="CACHE" select="false()" />

	<xsl:include href="../common/common-utils.xsl" />
	<xsl:include href="../common/namespace-vars.xsl" />
	<xsl:include href="../common/uqname-utils.xsl" />
	<xsl:include href="../common/uri-utils.xsl" />
	<xsl:include href="../compiler/base/util/compiler-misc-utils.xsl" />
	<xsl:include href="preprocessor.xsl" />

	<xsl:mode on-multiple-match="fail" on-no-match="fail" />

	<xsl:template as="document-node()" match="document-node(element(x:description))">
		<xsl:call-template name="x:perform-initial-check-for-schematron" />

		<xsl:variable as="map(xs:string, item())+" name="common-options-map">
			<xsl:map-entry key="'cache'" select="$CACHE" />
		</xsl:variable>

		<!--
			Generate Step3 wrapper
		-->
		<xsl:variable as="map(xs:string, item())" name="step3-wrapper-generation-options-map">
			<xsl:map>
				<xsl:sequence select="$common-options-map" />
				<xsl:map-entry key="'source-node'" select="." />
				<xsl:map-entry key="'stylesheet-location'" select="'generate-step3-wrapper.xsl'" />
				<xsl:map-entry key="'stylesheet-params'">
					<xsl:map>
						<xsl:map-entry key="xs:QName('ACTUAL-PREPROCESSOR-URI')"
							select="$STEP3-PREPROCESSOR-URI" />
					</xsl:map>
				</xsl:map-entry>
			</xsl:map>
		</xsl:variable>
		<!--<xsl:message select="'Generating Step 3 wrapper XSLT'" />-->
		<xsl:variable as="document-node()" name="step3-wrapper-doc"
			select="transform($step3-wrapper-generation-options-map)?output" />

		<!--
			Locate the Schematron schema
		-->
		<xsl:variable as="xs:anyURI" name="schematron-uri"
			select="local:locate-schematron-uri(x:description)" />

		<!--
			Step 1
		-->
		<xsl:variable as="document-node()" name="step1-transformed-doc">
			<xsl:choose>
				<xsl:when test="$STEP1-PREPROCESSOR-URI eq '#none'">
					<!-- Skip this step. Load the Schematron schema intact. -->
					<xsl:sequence select="doc($schematron-uri)" />
				</xsl:when>

				<xsl:otherwise>
					<xsl:variable as="map(xs:string, item())" name="step1-options-map">
						<xsl:map>
							<xsl:sequence select="$common-options-map" />
							<xsl:map-entry key="'source-location'" select="$schematron-uri" />
							<xsl:choose>
								<xsl:when test="$STEP1-PREPROCESSOR-DOC">
									<xsl:map-entry key="'stylesheet-node'"
										select="$STEP1-PREPROCESSOR-DOC" />
								</xsl:when>
								<xsl:otherwise>
									<xsl:map-entry key="'stylesheet-location'"
										select="$STEP1-PREPROCESSOR-URI" />
								</xsl:otherwise>
							</xsl:choose>
						</xsl:map>
					</xsl:variable>
					<!--<xsl:message select="'Performing Step 1'" />-->
					<xsl:sequence select="transform($step1-options-map)?output" />
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>

		<!--
			Step 2
		-->
		<xsl:variable as="document-node()" name="step2-transformed-doc">
			<xsl:choose>
				<xsl:when test="$STEP2-PREPROCESSOR-URI eq '#none'">
					<!-- Skip this step. No transformation. -->
					<xsl:sequence select="$step1-transformed-doc" />
				</xsl:when>

				<xsl:otherwise>
					<xsl:variable as="map(xs:string, item())" name="step2-options-map">
						<xsl:map>
							<xsl:sequence select="$common-options-map" />
							<xsl:map-entry key="'source-node'" select="$step1-transformed-doc" />
							<xsl:choose>
								<xsl:when test="$STEP2-PREPROCESSOR-DOC">
									<xsl:map-entry key="'stylesheet-node'"
										select="$STEP2-PREPROCESSOR-DOC" />
								</xsl:when>
								<xsl:otherwise>
									<xsl:map-entry key="'stylesheet-location'"
										select="$STEP2-PREPROCESSOR-URI" />
								</xsl:otherwise>
							</xsl:choose>
						</xsl:map>
					</xsl:variable>
					<!--<xsl:message select="'Performing Step 2'" />-->
					<xsl:sequence select="transform($step2-options-map)?output" />
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>

		<!--
			Step 3
		-->
		<xsl:variable as="map(xs:string, item())" name="step3-options-map">
			<xsl:map>
				<xsl:sequence select="$common-options-map" />
				<xsl:map-entry key="'source-node'" select="$step2-transformed-doc" />
				<xsl:map-entry key="'stylesheet-node'" select="$step3-wrapper-doc" />
			</xsl:map>
		</xsl:variable>
		<!--<xsl:message select="'Performing Step 3'" />-->
		<xsl:variable as="document-node()" name="step3-transformed-doc"
			select="transform($step3-options-map)?output" />

		<!--
			Workaround for the original Step 3 preprocessor not setting @xml:base.
		-->
		<xsl:copy select="$step3-transformed-doc">
			<xsl:for-each select="node()">
				<xsl:copy>
					<xsl:if test="self::element()">
						<xsl:attribute name="xml:base" select="$schematron-uri" />
					</xsl:if>
					<xsl:sequence select="attribute() | node()" />
				</xsl:copy>
			</xsl:for-each>
		</xsl:copy>
	</xsl:template>

	<xsl:template as="empty-sequence()" name="x:perform-initial-check-for-schematron">
		<xsl:context-item as="document-node(element(x:description))" use="required" />

		<xsl:for-each select="x:description[empty(@schematron)]">
			<xsl:message terminate="yes">
				<xsl:call-template name="x:prefix-diag-message">
					<xsl:with-param name="message" select="'Missing @schematron.'" />
				</xsl:call-template>
			</xsl:message>
		</xsl:for-each>
	</xsl:template>

	<!--
		Makes absolute URI from x:description/@schematron and resolves it with catalog
	-->
	<xsl:function as="xs:anyURI" name="local:locate-schematron-uri">
		<xsl:param as="element(x:description)" name="description" />

		<!-- Resolve with node base URI -->
		<xsl:variable as="xs:anyURI" name="schematron-uri"
			select="$description/@schematron/resolve-uri(., base-uri())" />

		<!-- Resolve with catalog -->
		<xsl:sequence select="x:resolve-xml-uri-with-catalog($schematron-uri)" />
	</xsl:function>

</xsl:stylesheet>
