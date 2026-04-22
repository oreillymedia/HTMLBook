<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="#all" version="3.0" xmlns:p="http://www.w3.org/ns/xproc"
	xmlns:x="http://www.jenitennison.com/xslt/xspec" xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

	<!--
		Returns true if node is user-content
	-->
	<xsl:function as="xs:boolean" name="x:is-user-content">
		<xsl:param as="node()" name="node" />

		<xsl:sequence
			select="
				exists(
				$node/ancestor-or-self::node() intersect
				(
				$node/ancestor::x:context/node()[not(self::x:param)]
				| $node/ancestor::x:expect/node()[not(self::x:label)]
				| $node/ancestor::x:param/node()
				| $node/ancestor::x:input/node()[not(self::p:document)]
				| $node/ancestor::x:option/node()[not(self::p:document)]
				| $node/ancestor::x:variable/node()
				)
				)"
		 />
	</xsl:function>

	<!--
		Parses @preserve-space in x:description and returns a sequence of element QName.
		For those elements, child whitespace-only text nodes should be preserved in XSpec
		node-selection.
	-->
	<xsl:function as="xs:QName*" name="x:parse-preserve-space">
		<xsl:param as="element(x:description)" name="description" />

		<xsl:sequence
			select="
				tokenize($description/@preserve-space, '\s+')[.]
				! resolve-QName(., $description)"
		 />
	</xsl:function>

	<!--
		Returns true if whitespace-only text node is significant in XSpec node-selection.
		False if it is ignorable.

		$preserve-space is usually obtained by x:parse-preserve-space().
	-->
	<xsl:function as="xs:boolean" name="x:is-ws-only-text-node-significant">
		<xsl:param as="text()" name="ws-only-text-node" />
		<xsl:param as="xs:QName*" name="preserve-space-qnames" />

		<xsl:sequence
			select="
				$ws-only-text-node
				/(
				parent::x:text
				or (ancestor::*[@xml:space][1]/@xml:space eq 'preserve')
				or (node-name(parent::*) = $preserve-space-qnames)
				)"
		 />
	</xsl:function>

</xsl:stylesheet>
