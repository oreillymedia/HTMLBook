<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:local="urn:x-xspec:common:report-sequence:local"
                xmlns:rep="urn:x-xspec:common:report-sequence"
                xmlns:saxon="http://saxon.sf.net/"
                xmlns:x="http://www.jenitennison.com/xslt/xspec"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                exclude-result-prefixes="#all"
                version="3.0">

   <!--
      This template can't be a function, because it contains xsl:result-document. Invoking
      xsl:result-document directly or indirectly in a function results in an error:
      "XTDE1480: Cannot execute xsl:result-document while evaluating xsl:function"
   -->
   <xsl:template name="rep:report-sequence" as="element()">
      <xsl:context-item use="absent" />

      <xsl:param name="sequence" as="item()*" required="yes" />
      <xsl:param name="report-name" as="xs:string" required="yes" />
      <xsl:param name="report-namespace" as="xs:string" select="$x:xspec-namespace" />
      <xsl:param name="result-file-threshold" as="xs:integer?" />

      <xsl:variable name="attribute-nodes" as="attribute()*"      select="$sequence[. instance of attribute()]" />
      <xsl:variable name="document-nodes"  as="document-node()*"  select="$sequence[. instance of document-node()]" />
      <xsl:variable name="namespace-nodes" as="namespace-node()*" select="$sequence[. instance of namespace-node()]" />
      <xsl:variable name="text-nodes"      as="text()*"           select="$sequence[. instance of text()]" />

      <xsl:variable name="content-wrapper" as="element(content-wrap)">
         <!-- Do not set a prefix in this element name. This prefix-less name undeclares the default
            namespace that pollutes the namespaces in the content. -->
         <xsl:element name="content-wrap" namespace="" />
      </xsl:variable>

      <xsl:variable name="report-element" as="element()">
         <xsl:element name="{$report-name}" namespace="{$report-namespace}">
            <xsl:choose>
               <!-- Empty -->
               <xsl:when test="empty($sequence)">
                  <xsl:attribute name="select" select="'()'" />
               </xsl:when>

               <!-- One or more atomic values -->
               <xsl:when test="$sequence instance of xs:anyAtomicType+">
                  <xsl:attribute name="select"
                     select="
                        ($sequence ! rep:report-atomic-value(.))
                        => string-join(',&#x0A;')" />
               </xsl:when>

               <!-- One or more nodes of the same type which can be a child of document node -->
               <xsl:when
                  test="
                     ($sequence instance of comment()+)
                     or ($sequence instance of element()+)
                     or ($sequence instance of processing-instruction()+)
                     or ($sequence instance of text()+)">
                  <xsl:attribute name="select"
                     select="'/' || rep:node-type($sequence[1]) || '()'" />

                  <xsl:copy select="$content-wrapper">
                     <xsl:apply-templates select="$sequence" mode="local:report-node" />
                  </xsl:copy>
               </xsl:when>

               <!-- Single document node -->
               <xsl:when test="$sequence instance of document-node()">
                  <!-- People do not always notice '/' in the report HTML. So express it more verbosely.
                     Also the expression must match the one in ../reporter/format-xspec-report.xsl. -->
                  <xsl:attribute name="select" select="'/self::document-node()'" />

                  <xsl:copy select="$content-wrapper">
                     <xsl:apply-templates select="$sequence" mode="local:report-node" />
                  </xsl:copy>
               </xsl:when>

               <!-- One or more nodes which can be stored in an element safely and without losing each position.
                  Those nodes include document nodes and text nodes. By storing them in an element, they will
                  be unwrapped and/or merged with adjacent nodes. When it happens, the report does not
                  represent the sequence precisely. That's ok, because
                  * Otherwise the report will be cluttered with pseudo elements.
                  * XSpec in general including its deq:deep-equal() inclines to merge them. -->
               <xsl:when
                  test="
                     ($sequence instance of node()+)
                     and not($attribute-nodes or $namespace-nodes)">
                  <xsl:attribute name="select" select="'/node()'" />

                  <xsl:copy select="$content-wrapper">
                     <xsl:apply-templates select="$sequence" mode="local:report-node" />
                  </xsl:copy>
               </xsl:when>

               <!-- Otherwise each item needs to be represented as a pseudo element -->
               <xsl:otherwise>
                  <xsl:attribute name="select">
                     <!-- Select the pseudo elements -->
                     <xsl:text>/*</xsl:text>

                     <xsl:choose>
                        <!-- If all items are instance of node, they can be expressed in @select.
                           (Document nodes are unwrapped, though.) -->
                        <xsl:when test="$sequence instance of node()+">
                           <xsl:variable name="expressions" as="xs:string+"
                              select="
                                 '@*'[$attribute-nodes],
                                 'namespace::*'[$namespace-nodes],
                                 'node()'[$sequence except ($attribute-nodes | $namespace-nodes)]" />
                           <xsl:variable name="multi-expr" as="xs:boolean"
                              select="count($expressions) ge 2" />

                           <xsl:text>/</xsl:text>
                           <xsl:if test="$multi-expr">
                              <xsl:text>(</xsl:text>
                           </xsl:if>
                           <xsl:value-of select="$expressions" separator=" | " />
                           <xsl:if test="$multi-expr">
                              <xsl:text>)</xsl:text>
                           </xsl:if>
                        </xsl:when>

                        <xsl:otherwise>
                           <!-- Not all items can be expressed in @select. Just leave the pseudo elements selected. -->
                        </xsl:otherwise>
                     </xsl:choose>
                  </xsl:attribute>

                  <xsl:copy select="$content-wrapper">
                     <xsl:sequence
                        select="$sequence ! local:report-pseudo-item(., $report-namespace)" />
                  </xsl:copy>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:element>
      </xsl:variable>

      <!-- Output the report element -->
      <xsl:choose>
         <!-- If too many nodes, save the report element as a separate file. -->
         <xsl:when test="count($report-element/descendant-or-self::node()) ge $result-file-threshold">
            <!-- URI of the separate file.
               Ensure that each report outputs to a unique URI (expath/xspec#67). -->
            <xsl:variable name="href" as="xs:string"
               select="'result-' || generate-id($report-element) || '.xml'" />

            <!-- Save the report element as the separate file.
               You can't unwrap the report element, because not all nodes can be located in the
               document root. -->
            <!-- Use @format to avoid clashes with <xsl:output> in another stylesheet which would
               otherwise govern the output of the separate file. -->
            <xsl:result-document href="{$href}" format="x:xml-report-serialization-parameters">
               <xsl:sequence select="$report-element" />
            </xsl:result-document>

            <!-- Alter the report element, discarding its stale @select -->
            <xsl:copy select="$report-element">
               <xsl:sequence select="attribute() except @select" />
               <xsl:attribute name="href" select="$href" />
            </xsl:copy>
         </xsl:when>

         <!-- Not too many nodes. Just output the report element as is. -->
         <xsl:otherwise>
            <xsl:sequence select="$report-element" />
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>

   <xsl:function name="local:report-pseudo-item" as="element()">
      <xsl:param name="item" as="item()" />
      <xsl:param name="report-namespace" as="xs:string" />

      <xsl:variable name="local-name-prefix" as="xs:NCName" select="xs:NCName('pseudo-')" />

      <xsl:choose>
         <xsl:when test="$item instance of xs:anyAtomicType">
            <xsl:element name="{$local-name-prefix}atomic-value" namespace="{$report-namespace}">
               <xsl:value-of select="rep:report-atomic-value($item)" />
            </xsl:element>
         </xsl:when>

         <xsl:when test="$item instance of node()">
            <xsl:element name="{$local-name-prefix}{rep:node-type($item)}" namespace="{$report-namespace}">
               <xsl:choose>
                  <!-- Can't apply templates to namespace nodes -->
                  <xsl:when test="$item instance of namespace-node()">
                     <xsl:sequence select="$item" />
                  </xsl:when>

                  <xsl:otherwise>
                     <xsl:apply-templates select="$item" mode="local:report-node" />
                  </xsl:otherwise>
               </xsl:choose>
            </xsl:element>
         </xsl:when>

         <xsl:when test="$item instance of function(*)">
            <xsl:element name="{$local-name-prefix}{rep:function-type($item)}"
               namespace="{$report-namespace}">
               <xsl:value-of select="local:serialize-adaptive($item)" />
            </xsl:element>
         </xsl:when>

         <xsl:otherwise>
            <!--
               Wrapped Java objects will fall here.
               https://www.saxonica.com/documentation/#!extensibility/functions/converting-args/converting-wrapped-java:
               > wrapped objects are a fourth subtype of item(), at the same level in the type
               > hierarchy as nodes, atomic values, and function items
            -->
            <xsl:element name="{$local-name-prefix}other" namespace="{$report-namespace}">
               <xsl:value-of select="local:serialize-adaptive($item)" />
            </xsl:element>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>

   <!--
      mode="local:report-node"
      Copies the nodes while wrapping whitespace-only text nodes in <x:ws>.
      You can't use @on-no-match="shallow-copy", because SUT may have xsl:template[@mode="#all"].
   -->
   <xsl:mode name="local:report-node" on-multiple-match="fail" on-no-match="fail" />

   <xsl:template match="document-node() | attribute() | node()" as="node()"
      mode="local:report-node">
      <xsl:call-template name="local:identity" />
   </xsl:template>

   <xsl:template match="text()[normalize-space() => not()]" as="element(x:ws)"
      mode="local:report-node">
      <xsl:element name="ws" namespace="{$x:xspec-namespace}">
         <xsl:sequence select="." />
      </xsl:element>
   </xsl:template>

   <!--
      Identity template
   -->
   <xsl:template as="node()" name="local:identity">
      <xsl:context-item as="node()" use="required" />

      <xsl:copy>
         <xsl:apply-templates mode="#current" select="attribute() | node()" />
      </xsl:copy>
   </xsl:template>

   <!--
      This function should be local:. But ../../test/report-sequence.xspec requires this to be
      exposed.
   -->
   <xsl:function name="rep:report-atomic-value" as="xs:string">
      <xsl:param name="value" as="xs:anyAtomicType" />

      <!-- Derived types must be handled before their base types -->
      <xsl:choose>
         <!-- String types -->
         <xsl:when test="$value instance of xs:normalizedString">
            <xsl:sequence select="local:report-atomic-value-as-constructor($value)" />
         </xsl:when>
         <xsl:when test="$value instance of xs:string">
            <xsl:sequence select="x:quote-with-apos($value)" />
         </xsl:when>

         <!-- Derived numeric types -->
         <xsl:when test="$value instance of xs:nonPositiveInteger">
            <xsl:sequence select="local:report-atomic-value-as-constructor($value)" />
         </xsl:when>
         <xsl:when test="$value instance of xs:long">
            <xsl:sequence select="local:report-atomic-value-as-constructor($value)" />
         </xsl:when>
         <xsl:when test="$value instance of xs:nonNegativeInteger">
            <xsl:sequence select="local:report-atomic-value-as-constructor($value)" />
         </xsl:when>

         <!-- Numeric types which can be expressed as numeric literals:
            https://www.w3.org/TR/xpath-31/#id-literals -->
         <xsl:when test="$value instance of xs:integer">
            <xsl:sequence select="string($value)" />
         </xsl:when>
         <xsl:when test="$value instance of xs:decimal">
            <xsl:sequence select="x:decimal-string($value)" />
         </xsl:when>
         <xsl:when test="$value instance of xs:double">
            <xsl:sequence
               select="
                  if (string($value) = ('NaN', 'INF', '-INF')) then
                     local:report-atomic-value-as-constructor($value)
                  else
                     local:serialize-adaptive($value)" />
         </xsl:when>

         <xsl:when test="$value instance of xs:QName">
            <xsl:sequence select="x:QName-expression($value)" />
         </xsl:when>

         <xsl:otherwise>
            <xsl:sequence select="local:report-atomic-value-as-constructor($value)" />
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>

   <xsl:function name="local:report-atomic-value-as-constructor" as="xs:string">
      <xsl:param name="value" as="xs:anyAtomicType" />

      <!-- Constructor usually has the same name as type -->
      <xsl:variable name="constructor-name" as="xs:string" select="rep:atom-type-UQName($value)" />

      <!-- Cast as either xs:integer or xs:string -->
      <xsl:variable name="casted-value" as="xs:anyAtomicType">
         <xsl:choose>
            <xsl:when test="$value instance of xs:integer">
               <!-- Force casting down to integer, by first converting to string -->
               <xsl:sequence select="string($value) cast as xs:integer" />
            </xsl:when>
            <xsl:otherwise>
               <xsl:sequence select="string($value)" />
            </xsl:otherwise>
         </xsl:choose>
      </xsl:variable>

      <!-- Constructor parameter:
         Either numeric literal of integer or string literal -->
      <xsl:variable name="costructor-param" as="xs:string"
         select="rep:report-atomic-value($casted-value)" />

      <xsl:sequence select="$constructor-name || '(' || $costructor-param || ')'" />
   </xsl:function>

   <!--
      Returns URIQualifiedName of atomic value type
         https://www.w3.org/TR/xslt-30/#built-in-types
      
      This function should be local:. But ../../test/report-sequence.xspec requires this to be
      exposed.
   -->
   <xsl:function name="rep:atom-type-UQName" as="xs:string">
      <xsl:param name="value" as="xs:anyAtomicType" />

      <xsl:choose>
         <xsl:when test="true()" use-when="function-available('saxon:type-annotation')">
            <xsl:sequence select="
                  $value
                  => saxon:type-annotation()
                  => x:UQName-from-QName()" />
         </xsl:when>

         <xsl:when test="true()">
            <xsl:variable name="local-name" as="xs:string">
               <!-- Derived types must be handled before their base types -->
               <xsl:choose>
                  <!--
                     https://www.w3.org/TR/xmlschema11-2/type-hierarchy-201104.longdesc.html
                  -->

                  <!-- Derived from xs:dateTime -->
                  <xsl:when test="$value instance of xs:dateTimeStamp" use-when="
                     type-available('xs:dateTimeStamp')">dateTimeStamp</xsl:when>

                  <!-- Derived from xs:decimal -->
                  <xsl:when test="$value instance of xs:byte">byte</xsl:when>
                  <xsl:when test="$value instance of xs:short">short</xsl:when>
                  <xsl:when test="$value instance of xs:int">int</xsl:when>
                  <xsl:when test="$value instance of xs:long">long</xsl:when>
                  <xsl:when test="$value instance of xs:positiveInteger">positiveInteger</xsl:when>
                  <xsl:when test="$value instance of xs:unsignedByte">unsignedByte</xsl:when>
                  <xsl:when test="$value instance of xs:unsignedShort">unsignedShort</xsl:when>
                  <xsl:when test="$value instance of xs:unsignedInt">unsignedInt</xsl:when>
                  <xsl:when test="$value instance of xs:unsignedLong">unsignedLong</xsl:when>
                  <xsl:when test="$value instance of xs:nonNegativeInteger">nonNegativeInteger</xsl:when>
                  <xsl:when test="$value instance of xs:negativeInteger">negativeInteger</xsl:when>
                  <xsl:when test="$value instance of xs:nonPositiveInteger">nonPositiveInteger</xsl:when>
                  <xsl:when test="$value instance of xs:integer">integer</xsl:when>

                  <!-- Derived from xs:duration -->
                  <xsl:when test="$value instance of xs:dayTimeDuration">dayTimeDuration</xsl:when>
                  <xsl:when test="$value instance of xs:yearMonthDuration">yearMonthDuration</xsl:when>

                  <!-- Derived from xs:string -->
                  <xsl:when test="$value instance of xs:language">language</xsl:when>
                  <xsl:when test="$value instance of xs:ENTITY">ENTITY</xsl:when>
                  <xsl:when test="$value instance of xs:ID">ID</xsl:when>
                  <xsl:when test="$value instance of xs:IDREF">IDREF</xsl:when>
                  <xsl:when test="$value instance of xs:NCName">NCName</xsl:when>
                  <xsl:when test="$value instance of xs:Name">Name</xsl:when>
                  <xsl:when test="$value instance of xs:NMTOKEN">NMTOKEN</xsl:when>
                  <xsl:when test="$value instance of xs:token">token</xsl:when>
                  <xsl:when test="$value instance of xs:normalizedString">normalizedString</xsl:when>

                  <!-- Derived from xs:NOTATION -->
                  <!-- Fall back on its base abstract type -->
                  <!-- TODO: Test this xsl:when branch -->
                  <xsl:when test="$value instance of xs:NOTATION">NOTATION</xsl:when>

                  <!-- Primitive atomic types except for abstract xs:NOTATION -->
                  <xsl:when test="$value instance of xs:anyURI">anyURI</xsl:when>
                  <xsl:when test="$value instance of xs:base64Binary">base64Binary</xsl:when>
                  <xsl:when test="$value instance of xs:boolean">boolean</xsl:when>
                  <xsl:when test="$value instance of xs:date">date</xsl:when>
                  <xsl:when test="$value instance of xs:dateTime">dateTime</xsl:when>
                  <xsl:when test="$value instance of xs:decimal">decimal</xsl:when>
                  <xsl:when test="$value instance of xs:double">double</xsl:when>
                  <xsl:when test="$value instance of xs:duration">duration</xsl:when>
                  <xsl:when test="$value instance of xs:float">float</xsl:when>
                  <xsl:when test="$value instance of xs:gDay">gDay</xsl:when>
                  <xsl:when test="$value instance of xs:gMonth">gMonth</xsl:when>
                  <xsl:when test="$value instance of xs:gMonthDay">gMonthDay</xsl:when>
                  <xsl:when test="$value instance of xs:gYear">gYear</xsl:when>
                  <xsl:when test="$value instance of xs:gYearMonth">gYearMonth</xsl:when>
                  <xsl:when test="$value instance of xs:hexBinary">hexBinary</xsl:when>
                  <xsl:when test="$value instance of xs:QName">QName</xsl:when>
                  <xsl:when test="$value instance of xs:string">string</xsl:when>
                  <xsl:when test="$value instance of xs:time">time</xsl:when>

                  <!--
                     Defined in XDM
                  -->
                  <xsl:when test="$value instance of xs:untypedAtomic">untypedAtomic</xsl:when>

                  <!--
                     Base of atomic types
                  -->
                  <xsl:otherwise>anyAtomicType</xsl:otherwise>
               </xsl:choose>
            </xsl:variable>

            <xsl:sequence select="x:known-UQName('xs:' || $local-name)" />
         </xsl:when>
      </xsl:choose>
   </xsl:function>

   <xsl:function name="local:serialize-adaptive" as="xs:string">
      <xsl:param name="item" as="item()" />

      <xsl:sequence
         select="
            serialize(
               $item,
               map {
                  'indent': true(),
                  'method': 'adaptive'
               }
            )" />
   </xsl:function>

   <!--
      Returns node type
         Example: 'element'

      This function should be local:. But ../../test/report-sequence.xspec requires this to be
      exposed.
   -->
   <xsl:function as="xs:string" name="rep:node-type">
      <xsl:param as="node()" name="node" />

      <xsl:choose>
         <xsl:when test="$node instance of attribute()">attribute</xsl:when>
         <xsl:when test="$node instance of comment()">comment</xsl:when>
         <xsl:when test="$node instance of document-node()">document-node</xsl:when>
         <xsl:when test="$node instance of element()">element</xsl:when>
         <xsl:when test="$node instance of namespace-node()">namespace-node</xsl:when>
         <xsl:when test="$node instance of processing-instruction()"
            >processing-instruction</xsl:when>
         <xsl:when test="$node instance of text()">text</xsl:when>
         <xsl:otherwise>node</xsl:otherwise>
      </xsl:choose>
   </xsl:function>

   <!--
      Returns type of function (including map and array).

      This function should be local:. But ../../test/report-sequence.xspec requires this to be
      exposed.
   -->
   <xsl:function as="xs:string" name="rep:function-type">

      <xsl:param as="function(*)" name="function" />

      <xsl:choose>
         <xsl:when test="$function instance of array(*)">array</xsl:when>
         <xsl:when test="$function instance of map(*)">map</xsl:when>
         <xsl:otherwise>function</xsl:otherwise>
      </xsl:choose>
   </xsl:function>

</xsl:stylesheet>