<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.w3.org/1999/XSL/TransformAlias"
    xmlns:wrap="urn:x-xspec:common:wrap" xmlns:x="http://www.jenitennison.com/xslt/xspec"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    exclude-result-prefixes="#all" version="3.0">

    <!-- Flags for deq:deep-equal() enclosed in ''. -->
    <xsl:function name="x:deep-equal-flags" as="xs:string">
        <xsl:param name="expect-element" as="element(x:expect)">
            <!-- $expect-element is used in the function by this name for XProc testing -->
        </xsl:param>
        <xsl:param name="xslt-version" as="xs:decimal"/>
        <xsl:sequence select="$x:apos || '1'[$xslt-version eq 1] || $x:apos"/>
    </xsl:function>

    <xsl:template name="define-impl-test-items" as="node()+">
        <xsl:comment> wrap $x:result into a document node if possible </xsl:comment>
        <variable name="{x:known-UQName('impl:test-items')}" as="item()*">
            <choose>
                <!-- From trying this out, it seems like it's useful for the test
                     to be able to test the nodes that are generated in the
                     $x:result as if they were *children* of the context node.
                     Have to experiment a bit to see if that really is the case.
                     TODO: To remove. Use directly $x:result instead. (expath/xspec#14) -->
                <when
                    test="exists(${x:known-UQName('x:result')}) and {x:known-UQName('wrap:wrappable-sequence')}(${x:known-UQName('x:result')})">
                    <sequence select="{x:known-UQName('wrap:wrap-nodes')}(${x:known-UQName('x:result')})" />
                </when>
                <otherwise>
                    <sequence select="${x:known-UQName('x:result')}" />
                </otherwise>
            </choose>                           
        </variable>
    </xsl:template>

</xsl:stylesheet>
