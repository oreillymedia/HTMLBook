(:
	Utilities common between XSLT and XQuery
:)

module namespace x = "http://www.jenitennison.com/xslt/xspec";

(:
	XSpec 'x' namespace URI
:)
declare variable $x:xspec-namespace as xs:anyURI := xs:anyURI('http://www.jenitennison.com/xslt/xspec');

(:
	U+0027
:)
declare variable $x:apos as xs:string := "'";

(:
	Returns numeric literal of xs:decimal. For more information, see
		https://www.w3.org/TR/xpath-31/#id-literals

		Example:
			in:  1
			out: '1.0'
:)
declare function x:decimal-string(
$decimal as xs:decimal
) as xs:string
{
	let $decimal-string as xs:string := string($decimal)
	return
		if (contains($decimal-string, '.')) then
			$decimal-string
		else
			($decimal-string || '.0')
};

(:
	Returns XPath expression of fn:QName() which represents the given xs:QName
:)
declare function x:QName-expression(
$qname as xs:QName
) as xs:string
{
	let $quoted-uri as xs:string := (
	$qname
	=> namespace-uri-from-QName()
	=> x:quote-with-apos()
	)
	return
		('QName(' || $quoted-uri || ", '" || $qname || "')")
};

(:
	Duplicates every apostrophe character in a string
	and quotes the whole string with apostrophes
:)
declare function x:quote-with-apos(
$input as xs:string
)
as xs:string
{
	let $escaped as xs:string := replace($input, $x:apos, ($x:apos || $x:apos), 'q')
	return
		($x:apos || $escaped || $x:apos)
};

(:
	Makes copies of namespaces from element.
	The standard 'xml' namespace is excluded.
:)
declare function x:copy-of-namespaces(
$element as element()
)
as namespace-node()*
{
	in-scope-prefixes($element)[. ne 'xml']
	! namespace {.} {namespace-uri-for-prefix(., $element)}
};

(:
	Makes copies of namespaces (sorted by their prefixes) from the element.
	The standard 'xml' and the element name prefix are excluded.

		Example:
			in:
				<prefix1:e xmlns="default"
				           xmlns:prefix3="three"
				           xmlns:prefix2="two"
				           xmlns:prefix1="one" />
			out:
				xmlns="default"
				xmlns:prefix2="two"
				xmlns:prefix3="three"
:)
declare function x:copy-of-additional-namespaces(
$element as element()
)
as namespace-node()*
{
	let $element-name-prefix as xs:string := (
	$element
	=> node-name()
	=> prefix-from-QName()
	=> string()
	)
	let $additional-namespace-nodes as namespace-node()* :=
	x:copy-of-namespaces($element)[name() ne $element-name-prefix]
	return
		(: Sort for better serialization (hopefully) :)
		for $prefix in sort($additional-namespace-nodes ! name())
		return
			$additional-namespace-nodes[name() eq $prefix]
};
