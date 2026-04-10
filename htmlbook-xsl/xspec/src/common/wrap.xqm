module namespace wrap = "urn:x-xspec:common:wrap";
declare namespace xs = "http://www.w3.org/2001/XMLSchema";

(:
  xspec/xspec#47 describes a problem in XSLT. Using "declare construction preserve;"
  in this library module (regardless of any construction declaration in the main module)
  prevents wrap:wrap-nodes from causing an analogous problem in XQuery if the compiled
  query is run with a schema-aware XQuery processor. Schema support is part of Saxon-EE
  but not Saxon-PE, Saxon-HE, or BaseX.
:)
declare construction preserve;

declare function wrap:wrappable-sequence(
$sequence as item()*
)
as xs:boolean
{
  every $item in $sequence satisfies wrap:wrappable-node($item)
};

declare function wrap:wrappable-node(
$item as item()
)
as xs:boolean
{
  (: Document node cannot wrap attribute node or namespace node.
    Doing so leads to error XPTY0004 or XQTY0024, depending on the
    node and the XQuery processor. :)
   $item instance of node()
   and not($item instance of attribute()
           or $item instance of namespace-node())
};

declare function wrap:wrap-nodes(
$nodes as node()*
)
as document-node()
{
document{ $nodes }
};