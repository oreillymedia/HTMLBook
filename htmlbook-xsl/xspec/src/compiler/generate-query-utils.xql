module namespace test = "http://www.jenitennison.com/xslt/unit-test";

(::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::)
(:  File:       generate-query-utils.xql                                    :)
(:  Author:     Jeni Tennsion                                               :)
(:  URI:        http://xspec.googlecode.com/                                :)
(:  Tags:                                                                   :)
(:    Copyright (c) 2008, 2010 Jeni Tennsion (see end of file.)             :)
(: ------------------------------------------------------------------------ :)


declare namespace fn = "http://www.w3.org/2005/xpath-functions";

declare function test:deep-equal($seq1 as item()*, $seq2 as item()*) as xs:boolean
{
  test:deep-equal($seq1, $seq2, 2.0)
};

declare function test:deep-equal(
    $seq1 as item()*,
    $seq2 as item()*,
    $version as xs:double
  ) as xs:boolean
{
  if ( $version = 1.0 ) then
    if ( $seq1 instance of xs:string and $seq2 instance of text()+ ) then
      test:deep-equal($seq1, fn:string-join($seq2, ''))
    else if ( $seq1 instance of xs:double and $seq2 instance of text()+ ) then
      test:deep-equal($seq1, xs:double(fn:string-join($seq2, '')))
    else if ( $seq1 instance of xs:decimal and $seq2 instance of text()+ ) then
      test:deep-equal($seq1, xs:decimal(fn:string-join($seq2, '')))
    else if ( $seq1 instance of xs:integer and $seq2 instance of text()+ ) then
      test:deep-equal($seq1, xs:integer(fn:string-join($seq2, '')))
    else
      test:deep-equal($seq1, $seq2)
  else if ( fn:empty($seq1) or fn:empty($seq2) ) then
    fn:empty($seq1) and fn:empty($seq2)
  else if ( fn:count($seq1) = fn:count($seq2) ) then
    every $i in (1 to fn:count($seq1))
    satisfies test:item-deep-equal($seq1[$i], $seq2[$i])
  else if ( $seq1 instance of text() and $seq2 instance of text()+ ) then
    test:deep-equal($seq1, text { fn:string-join($seq2, '') })
  else
    fn:false()
};

declare function test:item-deep-equal($item1 as item(), $item2 as item()) as xs:boolean
{
  if ( $item1 instance of node() and $item2 instance of node() ) then
    test:node-deep-equal($item1, $item2)
  else if ( fn:not($item1 instance of node()) and fn:not($item2 instance of node()) ) then
    fn:deep-equal($item1, $item2)
  else
    fn:false()
};

declare function test:node-deep-equal($node1 as node(), $node2 as node()) as xs:boolean
{
  if ( $node1 instance of document-node() and $node2 instance of document-node() ) then
    test:deep-equal(test:sorted-children($node1), test:sorted-children($node2))
  else if ( $node1 instance of element() and $node2 instance of element() ) then
    if ( fn:node-name($node1) eq fn:node-name($node2) ) then
      let $atts1 as attribute()* := test:sort-named-nodes($node1/@*)
      let $atts2 as attribute()* := test:sort-named-nodes($node2/@*)
        return
          if ( test:deep-equal($atts1, $atts2) ) then
            if ( $node1/text() = '...' and fn:count($node1/node()) = 1 ) then
              fn:true()
            else
              test:deep-equal(test:sorted-children($node1), test:sorted-children($node2))
          else
            fn:false()
    else
      fn:false()
  else if ( $node1 instance of text() and $node1 = '...' ) then
    fn:true()
  else if ( $node1 instance of text() and $node2 instance of text() ) then
    fn:string($node1) eq fn:string($node2)
  else if ( ( $node1 instance of attribute() and $node2 instance of attribute() )
            or ( $node1 instance of processing-instruction()
                 and $node2 instance of processing-instruction()) ) then
    fn:node-name($node1) eq fn:node-name($node2)
      and ( $node1 = '...' or fn:string($node1) eq fn:string($node2) )
  else if ( $node1 instance of comment() and $node2 instance of comment() ) then
    $node1 = '...' or fn:string($node1) eq fn:string($node2)
  else
    fn:false()
};

declare function test:sorted-children($node as node()) as node()*
{
  $node/child::node() 
  except ( $node/text()[fn:not(fn:normalize-space(.))], $node/test:message )
};

(: Aim to be identical to:
 :
 :     <xsl:perform-sort select="$nodes">
 :        <xsl:sort select="namespace-uri(.)" />
 :        <xsl:sort select="local-name(.)" />
 :     </xsl:perform-sort>
 :)
declare function test:sort-named-nodes($nodes as node()*) as node()*
{
  if ( fn:empty($nodes) ) then
    ()
  else
    let $idx := test:named-nodes-minimum($nodes)
      return (
        $nodes[$idx],
        test:sort-named-nodes(fn:remove($nodes, $idx))
      )
};

(: Return the "minimum" of $nodes, using the order defined by
 : test:sort-named-nodes().
 :)
declare function test:named-nodes-minimum($nodes as node()+) as xs:integer
{
  (: if there is only one node, this is the minimum :)
  if ( fn:empty($nodes[2]) ) then
    1
  (: if not, init the temp minimum on the first one, then walk through the sequence :)
  else
    test:named-nodes-minimum($nodes, fn:node-name($nodes[1]), 1, 2)
};

declare function test:named-nodes-minimum(
    $nodes as node()+,
    $min   as xs:QName,
    $idx   as xs:integer,
    $curr  as xs:integer
  ) as xs:integer
{
  if ( $curr gt fn:count($nodes) ) then
    $idx
  else if ( test:qname-lt(fn:node-name($nodes[$curr]), $min) ) then
    test:named-nodes-minimum($nodes, fn:node-name($nodes[$curr]), $curr, $curr + 1)
  else
    test:named-nodes-minimum($nodes, $min, $idx, $curr + 1)
};

declare function test:qname-lt($n1 as xs:QName, $n2 as xs:QName) as xs:boolean
{
  if ( fn:namespace-uri-from-QName($n1) eq fn:namespace-uri-from-QName($n2) ) then
    fn:local-name-from-QName($n1) lt fn:local-name-from-QName($n2)
  else
    fn:namespace-uri-from-QName($n1) lt fn:namespace-uri-from-QName($n2)
};

declare function test:report-value($value as item()*, $wrapper-name as xs:string) as element()
{
  test:report-value($value, $wrapper-name, 'http://www.jenitennison.com/xslt/xspec')
};

declare function test:report-value(
    $value as item()*,
    $wrapper-name as xs:string,
    $wrapper-ns as xs:string
  ) as element()
{
  element { fn:QName($wrapper-ns, $wrapper-name) } {
    if ( $value[1] instance of attribute() ) then (
        attribute { 'select' } { '/*/(@* | node())' },
        element { fn:QName($wrapper-ns, 'temp') } { $value }
      )
    else if ( $value instance of node()+ ) then (
        if ( $value instance of document-node() ) then
          attribute { 'select' } { '/' }
        else if ( fn:not($value instance of element()+) ) then
          attribute { 'select' } { '/node()' }
        else
          ()
        ,
        if ( fn:count($value//node()) > 1000 ) then
          fn:error((), 'TODO: Write the value within a file...')
        else
          (: TODO: The original stylesheet use a mode to do a bit
             different copy, to preserve withespaces... :)
          $value
      )
    else
      attribute { 'select' } {
        if ( fn:empty($value) ) then
          '()'
        else if ( $value instance of item() ) then
          test:report-atomic-value($value)
        else
          fn:concat('(', fn:string-join(for $v in $value return test:report-atomic-value($v), ', '), ')')
      }
  }
};

declare function test:report-atomic-value($value as item()) as xs:string
{
  if ( $value instance of xs:string ) then
    fn:concat("'", fn:replace($value, "'", "''"), "'")
  else if ( $value instance of xs:integer or
            $value instance of xs:decimal or
            $value instance of xs:double ) then
    fn:string($value)
  else if ( $value instance of xs:QName ) then
    fn:concat("QName('",
           fn:namespace-uri-from-QName($value),
           "', '",
           if ( fn:prefix-from-QName($value) ) then
             fn:concat(fn:prefix-from-QName($value), ':') 
           else
             '',
           fn:local-name-from-QName($value),
           "')")
  else
    fn:concat(test:atom-type($value), '(', test:report-atomic-value(fn:string($value)), ')')
};

declare function test:atom-type($value as xs:anyAtomicType) as xs:string
{
  if ( $value instance of xs:string ) then
    'xs:string'
  else if ( $value instance of xs:boolean ) then
    'xs:boolean'
  else if ( $value instance of xs:double ) then
    'xs:double'
  else if ( $value instance of xs:anyURI ) then
    'xs:anyURI'
  else if ( $value instance of xs:dateTime ) then
    'xs:dateTime'
  else if ( $value instance of xs:date ) then
    'xs:date'
  else if ( $value instance of xs:time ) then
    'xs:time'
  else
    'xs:anyAtomicType'
};


(: ------------------------------------------------------------------------ :)
(:  DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS COMMENT.               :)
(:                                                                          :)
(:  Copyright (c) 2008, 2010 Jeni Tennsion                                  :)
(:                                                                          :)
(:  The contents of this file are subject to the MIT License (see the URI   :)
(:  http://www.opensource.org/licenses/mit-license.php for details).        :)
(:                                                                          :)
(:  Permission is hereby granted, free of charge, to any person obtaining   :)
(:  a copy of this software and associated documentation files (the         :)
(:  "Software"), to deal in the Software without restriction, including     :)
(:  without limitation the rights to use, copy, modify, merge, publish,     :)
(:  distribute, sublicense, and/or sell copies of the Software, and to      :)
(:  permit persons to whom the Software is furnished to do so, subject to   :)
(:  the following conditions:                                               :)
(:                                                                          :)
(:  The above copyright notice and this permission notice shall be          :)
(:  included in all copies or substantial portions of the Software.         :)
(:                                                                          :)
(:  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,         :)
(:  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF      :)
(:  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  :)
(:  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY    :)
(:  CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,    :)
(:  TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE       :)
(:  SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                  :)
(: ------------------------------------------------------------------------ :)
