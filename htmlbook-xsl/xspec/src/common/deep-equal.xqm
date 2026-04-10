module namespace deq = "urn:x-xspec:common:deep-equal";

import module namespace x = "http://www.jenitennison.com/xslt/xspec"
  at "../common/common-utils.xqm";

declare function deq:deep-equal(
    $seq1 as item()*,
    $seq2 as item()*,
    $flags as xs:string
  ) as xs:boolean
{
  if (contains($flags, '1')) then
    deq:deep-equal-v1($seq1, $seq2, $flags)

  else if (($seq1 instance of attribute()+) and
   (some $att in $seq1 satisfies (node-name($att) = QName($x:xspec-namespace,'x:attrs') and string($att) eq '...'))) then
   let $seq1-without-x-other as attribute()* := $seq1[not(node-name(.) = QName($x:xspec-namespace,'x:attrs'))]
   let $seq2-without-extras as attribute()* := $seq2[node-name(.) = $seq1/node-name()]
   return deq:deep-equal(
     $seq1-without-x-other,
     $seq2-without-extras,
     $flags
   )

  else if (empty($seq1) or empty($seq2)) then
    empty($seq1) and empty($seq2)

  else if (count($seq1) = count($seq2)) then
    every $i in (1 to count($seq1))
    satisfies deq:item-deep-equal($seq1[$i], $seq2[$i], $flags)

  else if ( $seq1 instance of text() and $seq2 instance of text()+ ) then
    deq:deep-equal($seq1, text { string-join($seq2) }, $flags)

  else
    false()
};

declare %private function deq:deep-equal-v1(
  $seq1 as item()*,
  $seq2 as item()*,
  $flags as xs:string
) as xs:boolean
{
  let $seq2-adapted as xs:anyAtomicType? := (
    if ($seq2 instance of text()+) then
      let $seq2-string as xs:string := string-join($seq2)
      return
        typeswitch ($seq1)
          case xs:string  return $seq2-string
          case xs:double  return $seq2-string[. castable as xs:double]  => xs:double()
          case xs:decimal return $seq2-string[. castable as xs:decimal] => xs:decimal()
          default         return ()
    else
      ()
  )
  return
    deq:deep-equal(
      $seq1,
      ($seq2-adapted, $seq2)[1],
      translate($flags, '1', '')
    )
};

(:
  This function should be %private. But ../../test/deep-equal.xspec requires this to be exposed.
:)
declare function deq:item-deep-equal(
  $item1 as item(),
  $item2 as item(),
  $flags as xs:string
) as xs:boolean
{
  if ( $item1 instance of node() and $item2 instance of node() ) then
    deq:node-deep-equal($item1, $item2, $flags)
  else if (not($item1 instance of node()) and not($item2 instance of node())) then
    deep-equal($item1, $item2)
  else
    false()
};

(:
  This function should be %private. But ../../test/deep-equal.xspec requires this to be exposed.
:)
declare function deq:node-deep-equal(
  $node1 as node(),
  $node2 as node(),
  $flags as xs:string
) as xs:boolean
{
  if ( $node1 instance of document-node() and $node2 instance of document-node() ) then
    deq:deep-equal(deq:sorted-children($node1, $flags), deq:sorted-children($node2, $flags), $flags)

  else if ( $node1 instance of element() and $node2 instance of element() ) then
    deq:element-deep-equal($node1, $node2, $flags)

  else if ( $node1 instance of text() and $node1 = '...' ) then
    true()

  else if ( $node1 instance of text() and $node2 instance of text() ) then
    string($node1) eq string($node2)

  else if ( ( $node1 instance of attribute() and $node2 instance of attribute() )
            or ( $node1 instance of comment() and $node2 instance of comment() )
            or ( $node1 instance of processing-instruction()
                 and $node2 instance of processing-instruction())
            or ( $node1 instance of namespace-node()
                 and $node2 instance of namespace-node() ) ) then
    deep-equal(node-name($node1), node-name($node2))
      and (string($node1) = (string($node2), '...'))

  else
    false()
};

declare %private function deq:element-deep-equal(
  $elem1 as element(),
  $elem2 as element(),
  $flags as xs:string
) as xs:boolean
{
  let $node-name-equal as xs:boolean := (node-name($elem1) eq node-name($elem2))

  let $attrs-equal as xs:boolean :=
    deq:deep-equal(
      deq:sort-named-nodes($elem1/attribute()),
      deq:sort-named-nodes($elem2/attribute()),
      $flags
    )

  let $children-equal as xs:boolean := (
    $elem1[count(node()) eq 1][text() = '...']
    or
    deq:deep-equal(
      deq:sorted-children($elem1, $flags),
      deq:sorted-children($elem2, $flags),
      $flags
    )
  )

  return
    ($node-name-equal and $attrs-equal and $children-equal)
};

(:
  This function should be %private. But ../../test/deep-equal.xspec requires this to be exposed.
:)
declare function deq:sorted-children(
  $node as node(),
  $flags as xs:string
) as node()*
{
  let $ignorable-ws-only-text-nodes as text()* := (
    if (contains($flags, 'w') and not($node/self::x:ws)) then
      $node/text()[normalize-space() => not()]
    else
      ()
  )
  return
    ($node/child::node() except $ignorable-ws-only-text-nodes)
};

declare %private function deq:sort-named-nodes(
  $nodes as node()*
) as node()*
{
  if (empty($nodes)) then
    ()
  else
    let $idx := deq:named-nodes-minimum($nodes)
      return (
        $nodes[$idx],
        deq:sort-named-nodes(remove($nodes, $idx))
      )
};

(: Return the "minimum" of $nodes, using the order defined by
 : deq:sort-named-nodes().
 :)
declare %private function deq:named-nodes-minimum(
  $nodes as node()+
) as xs:integer
{
  (: if there is only one node, this is the minimum :)
  if (empty($nodes[2])) then
    1
  (: if not, init the temp minimum on the first one, then walk through the sequence :)
  else
    deq:named-nodes-minimum($nodes, node-name($nodes[1]), 1, 2)
};

declare %private function deq:named-nodes-minimum(
  $nodes as node()+,
  $min   as xs:QName,
  $idx   as xs:integer,
  $curr  as xs:integer
) as xs:integer
{
  if ($curr gt count($nodes)) then
    $idx
  else if (deq:qname-lt(node-name($nodes[$curr]), $min)) then
    deq:named-nodes-minimum($nodes, node-name($nodes[$curr]), $curr, $curr + 1)
  else
    deq:named-nodes-minimum($nodes, $min, $idx, $curr + 1)
};

declare %private function deq:qname-lt(
  $n1 as xs:QName,
  $n2 as xs:QName
) as xs:boolean
{
  if (namespace-uri-from-QName($n1) eq namespace-uri-from-QName($n2)) then
    local-name-from-QName($n1) lt local-name-from-QName($n2)
  else
    namespace-uri-from-QName($n1) lt namespace-uri-from-QName($n2)
};

