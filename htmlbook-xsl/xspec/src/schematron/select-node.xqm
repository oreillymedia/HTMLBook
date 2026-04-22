module namespace sn = "urn:x-xspec:schematron:select-node";
declare namespace svrl = "http://purl.oclc.org/dsdl/svrl";
declare namespace xquery = "http://basex.org/modules/xquery";
declare namespace xs = "http://www.w3.org/2001/XMLSchema";

(:
  Evaluates the given XPath expression in the context of the given source node,
  with the given namespaces.

  NOTE: This function requires BaseX due to the xquery:eval function.
  XQS also uses xquery:eval, so XSpec/XQS usage already requires BaseX. 
:)
declare function sn:select-node(
$source-node as node(),
$expression as xs:string,
$namespaces as element(svrl:ns-prefix-in-attribute-values)*
)
as node()?
{
  let $ns-bindings as xs:string* :=
    $namespaces ! ('declare namespace ' || ./@prefix || ' = "' || ./@uri || '"; ')
  return
    xquery:eval($ns-bindings || $expression, map{'': $source-node})
};

declare function sn:node-or-error(
$maybe-node as item()*,
$expression as xs:string,
$error-owner as xs:string
)
as item()*
{
  if ($maybe-node instance of node())
  then $maybe-node
  else
    let $description as xs:string := concat(
      'ERROR in ',
      $error-owner,
      ': Expression ',
      $expression,
      ' should point to one node.'
    )
    return error((),$description)
};