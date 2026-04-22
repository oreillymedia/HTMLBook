<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="#all" version="3.0"
	xmlns:x="http://www.jenitennison.com/xslt/xspec" xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

	<!--
		Saxon version packed as uint64, based on 'xsl:product-version' system property, ignoring
		edition (EE, PE, HE).
		An empty sequence, if XSLT processor is not Saxon.
			Example:
				"EE 9.9.1.5"  -> 2533313445167109 (0x0009000900010005)
				"HE 9.3.0.11" -> 2533287675297809 (0x0009000300000011)
				"HE 10.0"     -> 2814749767106560 (0x000A000000000000)
	-->
	<xsl:variable as="xs:integer?" name="x:saxon-version">
		<xsl:if test="system-property('xsl:product-name') eq 'SAXON'">
			<xsl:variable as="xs:integer+" name="ver-components"
				select="
					system-property('xsl:product-version')
					=> x:extract-version()" />
			<xsl:sequence select="x:pack-version($ver-components)" />
		</xsl:if>
	</xsl:variable>

	<!--
		XSpec version (same as last released version of add-on)
	-->
	<xsl:variable as="xs:string" name="x:xspec-version" select="unparsed-text('VERSION')"/>

	<!--
		Packs w.x.y.z version into uint64, assuming every component is uint16.
		x, y and z are optional (0 by default).
			Example:
				(76,  0, 3809, 132) -> 21392098479636612 (0x004C00000EE10084)
				( 1,  2,    3     ) ->   281483566841856 (0x0001000200030000)
				(10, 11           ) ->  2814797011746816 (0x000A000B00000000)
				( 9               ) ->  2533274790395904 (0x0009000000000000)
	-->
	<xsl:function as="xs:integer" name="x:pack-version">
		<xsl:param as="xs:integer+" name="ver-components" />

		<!-- 0x10000 -->
		<xsl:variable as="xs:integer" name="x10000" select="65536" />

		<!-- Return a value only when the input is valid. Return nothing if not valid, which
			effectively causes an error. -->
		<xsl:if
			test="
				(: 5th+ component is not allowed :)
				(count($ver-components) le 4)
				
				(: Every component must be uint16 :)
				and empty($ver-components[. ge $x10000]) and empty($ver-components[. lt 0])">
			<xsl:variable as="xs:integer" name="w" select="$ver-components[1]" />
			<xsl:variable as="xs:integer" name="x" select="($ver-components[2], 0)[1]" />
			<xsl:variable as="xs:integer" name="y" select="($ver-components[3], 0)[1]" />
			<xsl:variable as="xs:integer" name="z" select="($ver-components[4], 0)[1]" />

			<xsl:variable as="xs:integer" name="high32" select="($w * $x10000) + $x" />
			<xsl:variable as="xs:integer" name="low32" select="($y * $x10000) + $z" />
			<xsl:sequence select="($high32 * $x10000 * $x10000) + $low32" />
		</xsl:if>
	</xsl:function>

	<!--
		Extracts 4 version integers from string, assuming it contains zero or one
		"#.#.#.#" or "#.#" (# = ASCII numbers).
		Returns an empty sequence, if string contains no "#.#.#.#" or "#.#".
			Example:
				"HE 9.9.1.5"  -> 9, 9, 1, 5
				"１.２.３.４" -> ()
				"HE 10.1"     -> 10, 1, 0, 0
	-->
	<xsl:function as="xs:integer*" name="x:extract-version">
		<xsl:param as="xs:string" name="input" />

		<xsl:variable as="xs:string" name="regex" xml:space="preserve">
			([0-9]+)		<!-- group 1 -->
			\.
			([0-9]+)		<!-- group 2 -->
			(?:
				\.
				([0-9]+)	<!-- group 3 -->
				\.
				([0-9]+)	<!-- group 4 -->
			)?
		</xsl:variable>
		<xsl:analyze-string flags="x" regex="{$regex}" select="$input">
			<xsl:matching-substring>
				<xsl:sequence
					select="
						(1 to 4)
						! (regex-group(.)[.], 0)[1]
						! xs:integer(.)"
				 />
			</xsl:matching-substring>
		</xsl:analyze-string>
	</xsl:function>

</xsl:stylesheet>
