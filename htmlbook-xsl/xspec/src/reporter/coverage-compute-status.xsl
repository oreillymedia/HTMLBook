<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0"
    xmlns:local="urn:x-xspec:reporter:coverage-report:local"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:XSLT="http://www.w3.org/1999/XSL/Transform" exclude-result-prefixes="#all">

    <!-- This file uses the "XSLT" prefix for names of elements in the stylesheet
        whose coverage is being reported and the conventional "xsl" prefix for
        the code in this stylesheet. -->

    <!-- The category-based-on-trace-data accumulator is raw information about whether a node
        is in the trace. Other logic builds upon this information. -->
    <xsl:accumulator name="category-based-on-trace-data" as="xs:string*" initial-value="()">
        <xsl:accumulator-rule match="element() | text()">
            <xsl:variable name="hits-on-node" as="element(hit)*"
                select="local:hits-on-node(.)"/>
            <xsl:choose>
                <xsl:when test="exists($hits-on-node)">
                    <xsl:sequence select="'hit'"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:sequence select="'missed'"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:accumulator-rule>
    </xsl:accumulator>

    <!-- The module-id-for-node accumulator computes the module ID for a stylesheet.
        The computation occurs only on the outermost element of a stylesheet module.
        The value can be retrieved for any node of the module because accumulators
        hold their values until they match a different accumulator rule. -->
    <xsl:accumulator name="module-id-for-node" as="xs:integer?" initial-value="()">
        <xsl:accumulator-rule match="XSLT:stylesheet | XSLT:transform | XSLT:package">
            <xsl:variable name="stylesheet-uri" as="xs:anyURI"
                select="base-uri(.)" />
            <xsl:variable name="uri" as="xs:string"
                select="if (starts-with($stylesheet-uri, '/'))
                then ('file:' || $stylesheet-uri)
                else $stylesheet-uri" />
            <xsl:sequence select="key('modules', $uri, $trace)/@moduleId" />
        </xsl:accumulator-rule>
    </xsl:accumulator>

    <!--
      mode="coverage"

      This mode implements the rules described in docs/xslt-code-coverage-by-element.md.

      Priority values of templates in this mode ensure correct rule selection, such as
      when templates match descendants via different paths. Tests for rule selection are
      in test/end-to-end/cases-coverage.
   -->
    <xsl:mode name="coverage" on-multiple-match="fail" on-no-match="fail" />

    <!-- Always Ignore -->
    <!-- TODO: Design document suggests maybe switching to Always Hit rule for XSLT:stylesheet and XSLT:transform -->
    <xsl:template match="
        XSLT:stylesheet
        | XSLT:transform
        | XSLT:package

        | XSLT:accept
        | XSLT:accumulator
        | XSLT:attribute-set
        | XSLT:character-map
        | XSLT:decimal-format
        | XSLT:expose
        | XSLT:global-context-item
        | XSLT:import
        | XSLT:import-schema
        | XSLT:include
        | XSLT:key
        | XSLT:mode
        | XSLT:namespace-alias
        | XSLT:output
        | XSLT:override
        | XSLT:preserve-space
        | XSLT:strip-space
        | XSLT:use-package

        | XSLT:output-character

        | processing-instruction()
        | document-node()"
        mode="coverage"
        as="xs:string"
        priority="30">
        <xsl:sequence select="'ignored'"/>
    </xsl:template>

    <xsl:template match="text()[normalize-space() = '' and not(parent::XSLT:text)]"
        mode="coverage"
        as="xs:string"
        priority="30">
        <xsl:sequence select="'whitespace'"/>
    </xsl:template>

    <xsl:template match="comment()"
        mode="coverage"
        as="xs:string"
        priority="30">
        <xsl:sequence select="'comment'"/>
    </xsl:template>

    <!-- A node within a top-level non-XSLT element -->
    <!-- In case a descendant is an XSLT element, priority makes us match this
      template instead of one that handles ordinary XSLT instructions outside
      top-level non-XSLT elements. -->
    <xsl:template match="
        XSLT:stylesheet/*[not(namespace-uri() = 'http://www.w3.org/1999/XSL/Transform')]/descendant-or-self::node()
        | XSLT:transform/*[not(namespace-uri() = 'http://www.w3.org/1999/XSL/Transform')]/descendant-or-self::node()"
        as="xs:string"
        mode="coverage"
        priority="10">
        <xsl:sequence select="'ignored'"/>
    </xsl:template>

    <!-- Ignore Element and All Descendants -->
    <xsl:template match="
        XSLT:attribute-set/XSLT:attribute/descendant-or-self::node()
        | XSLT:accumulator-rule/descendant-or-self::node()"
        as="xs:string"
        mode="coverage"
        priority="20">
        <xsl:sequence select="'ignored'"/>
    </xsl:template>

    <!-- Use Descendant Data -->
    <xsl:template
        match="
        XSLT:assert[child::node()]
        | XSLT:catch
        | XSLT:fallback
        | XSLT:map
        | XSLT:map-entry
        | XSLT:matching-substring
        | XSLT:non-matching-substring
        | XSLT:on-completion
        | XSLT:perform-sort
        | XSLT:otherwise
        | XSLT:try[not(exists(@select))]
        | XSLT:when
        | XSLT:where-populated"
        as="xs:string"
        mode="coverage"
        name="use-descendant-data">
        <xsl:choose>
            <xsl:when test="empty(child::node())">
                <xsl:sequence select="'unknown'"/>
            </xsl:when>
            <xsl:when test="descendant::node()/accumulator-before('category-based-on-trace-data') = 'hit'">
                <!-- If at least one descendant is hit, mark as hit -->
                <xsl:sequence select="'hit'"/>
            </xsl:when>
            <xsl:otherwise>
                <!--
                    Iterate over descendants and follow this logic:
                    A. Upon finding any untraceable executable descendant, return 'unknown'
                       and break out of loop. (Note: Nodes like comment() are untraceable
                       but not executable, so they don't affect this iteration.)
                    B. If node has any traceable executable descendants, node is a candidate for
                       'missed', but condition A still applies as iteration continues.
                    C. At end of loop, if condition A did not apply, the tentative status
                       becomes the status.
                -->
                <xsl:variable name="descendants" as="node()*">
                    <xsl:choose>
                        <xsl:when test="self::XSLT:try">
                            <!--
                                Special case for xsl:try: Not all descendants matter for the
                                choice between missed and unknown. Consider only the children
                                other than xsl:catch and xsl:fallback, and the descendants of
                                those children.
                            -->
                            <xsl:sequence select="child::node()[not(self::XSLT:catch or self::XSLT:fallback)]/
                                descendant-or-self::node()"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:sequence select="descendant::node()"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <xsl:iterate select="$descendants">
                    <xsl:param name="tentative-status" as="xs:string" select="'unknown'" />
                    <xsl:on-completion>
                        <xsl:sequence select="$tentative-status" />
                    </xsl:on-completion>
                    <xsl:variable name="untraceable" as="xs:string?">
                        <xsl:apply-templates select="." mode="untraceable-in-instruction" />
                    </xsl:variable>
                    <xsl:choose>
                        <xsl:when test="$untraceable eq 'untraceable executable'">
                            <xsl:sequence select="'unknown'" />
                            <xsl:break/>
                        </xsl:when>
                        <xsl:when test="$untraceable eq 'traceable executable'">
                            <xsl:next-iteration>
                                <xsl:with-param name="tentative-status" select="'missed'" />
                            </xsl:next-iteration>
                        </xsl:when>
                    </xsl:choose>
                </xsl:iterate>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Use Parent Data (directly) -->
    <xsl:template match="
        XSLT:context-item (: xspec/xspec#1410 :)
        | XSLT:merge-action
        | XSLT:merge-source
        | XSLT:param[not(parent::XSLT:stylesheet or parent::XSLT:transform)]"
        as="xs:string"
        mode="coverage">
        <xsl:sequence select="parent::*/accumulator-before('category-based-on-trace-data')"/>
    </xsl:template>

    <!-- Use Parent Status (computed) -->
    <xsl:template match="
        XSLT:sort
        | XSLT:with-param"
        as="xs:string"
        mode="coverage"
        name="use-parent-status">
        <xsl:apply-templates select="parent::*" mode="#current"/>
    </xsl:template>

    <!-- Use Trace Data -->
    <xsl:template match="element()"
        as="xs:string"
        mode="coverage">
        <xsl:sequence select="accumulator-before('category-based-on-trace-data')"/>
    </xsl:template>

    <!-- Element-Specific rule for XSLT:variable -->
    <xsl:template match="XSLT:variable"
        as="xs:string"
        mode="coverage">
        <xsl:choose>
            <xsl:when test="accumulator-before('category-based-on-trace-data') eq 'hit'">
                <xsl:sequence select="'hit'"/>
            </xsl:when>
            <xsl:when test="parent::XSLT:stylesheet or parent::XSLT:transform">
                <!-- Global variables effectively follow the Use Trace Data rule. -->
                <xsl:sequence select="'missed'"/>
            </xsl:when>
            <xsl:when test="following-sibling::*[not(self::XSLT:variable)]">
                <xsl:apply-templates select="following-sibling::*[not(self::XSLT:variable)][1]"
                    mode="#current"/>
            </xsl:when>
            <xsl:otherwise>
                <!-- Local variable with no following siblings except other local variables -->
                <xsl:sequence select="'missed'"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Element-Specific rule for XSLT:merge-key -->
    <xsl:template match="XSLT:merge-key"
        as="xs:string"
        mode="coverage">
        <xsl:apply-templates select="ancestor::XSLT:merge[1]"
            mode="#current"/>
    </xsl:template>

    <!-- Element-Specific rule for descendants of XSLT:merge-key -->
    <xsl:template match="XSLT:merge-key/descendant::node()"
        as="xs:string"
        mode="coverage"
        priority="5">
        <xsl:variable name="xsl-merge-status" as="xs:string">
            <xsl:apply-templates select="ancestor::XSLT:merge[1]"
                mode="#current"/>
        </xsl:variable>
        <xsl:sequence select="
                if ($xsl-merge-status eq 'hit') then
                    'unknown'
                else
                    'missed'
                "/>
    </xsl:template>

    <!-- Element-Specific rule for XSLT:sequence -->
    <!-- Usually, we expect to use descendant data in Saxon 12.4+, but if xsl:sequence
        has a hit in the trace, use it. -->
    <xsl:template match="XSLT:sequence"
        as="xs:string"
        mode="coverage">
        <xsl:choose>
            <xsl:when test="accumulator-before('category-based-on-trace-data') eq 'hit'">
                <xsl:sequence select="'hit'"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="use-descendant-data"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Element-Specific rule for child elements of XSLT:sort -->
    <!-- (Child comment or PI nodes use higher-priority template.) -->
    <xsl:template match="XSLT:sort/*"
        as="xs:string"
        mode="coverage"
        priority="5">
        <!-- Use priority here and call use-parent-status by name instead of
            adding XSLT:sort/* to that template's match attribute, to ensure
            the Use Parent Status rule is applied even if the child of xsl:sort
            has a template that matches it directly. -->
        <xsl:call-template name="use-parent-status" />
    </xsl:template>

    <!-- Element-Specific rule for descendants of XSLT:sort deeper than children -->
    <xsl:template match="XSLT:sort/*/descendant::node()"
        as="xs:string"
        mode="coverage"
        priority="5">
        <xsl:choose>
            <xsl:when test="accumulator-before('category-based-on-trace-data') eq 'hit'">
                <xsl:sequence select="'hit'" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="'unknown'" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Node-Specific rule for text nodes -->
    <!-- Usually, we expect to use parent status in Saxon 12.4+, but there
        are some exceptions. -->
    <xsl:template match="text()"
        as="xs:string"
        mode="coverage">
        <xsl:choose>
            <xsl:when test="accumulator-before('category-based-on-trace-data') eq 'hit'">
                <xsl:sequence select="'hit'"/>
            </xsl:when>
            <xsl:when test="parent::XSLT:if or parent::XSLT:param/parent::XSLT:template">
                <!-- Trace hit for XSLT:if says the condition was checked but doesn't indicate the outcome. -->
                <!-- XSLT:template/XSLT:param follows Use Parent Data rule and doesn't indicate if the
                    default value of the template parameter was used. -->
                <xsl:sequence select="'unknown'"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="use-parent-status"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!--
      mode="untraceable-in-instruction"
   -->
    <xsl:mode name="untraceable-in-instruction" on-multiple-match="fail" on-no-match="fail" />

    <!-- Low-priority fallback template rule -->
    <xsl:template match="node()" mode="untraceable-in-instruction"
        as="xs:string" priority="-10">
        <xsl:sequence select="'traceable executable'"/>
    </xsl:template>

    <!-- Non-executable nodes that can occur in an instruction -->
    <xsl:template match="
        text()[normalize-space() = '' and not(parent::XSLT:text)]
        | processing-instruction()
        | comment()"
        mode="untraceable-in-instruction"
        as="empty-sequence()"/>

    <!-- Untraceable elements that can occur in an instruction -->
    <xsl:template match="
        XSLT:catch
        | XSLT:fallback
        | XSLT:iterate/XSLT:param
        | XSLT:map
        | XSLT:map-entry
        | XSLT:matching-substring
        | XSLT:merge-action
        | XSLT:merge-key
        | XSLT:merge-source
        | XSLT:non-matching-substring
        | XSLT:on-completion
        | XSLT:on-empty
        | XSLT:on-non-empty
        | XSLT:otherwise
        | XSLT:perform-sort[@select]
        | XSLT:perform-sort[XSLT:sort][count(*) = 1]
        | XSLT:sequence[empty(node())]
        | XSLT:sort
        | XSLT:template/XSLT:param[@select]
        | XSLT:when
        | XSLT:where-populated
        | XSLT:with-param"
        mode="untraceable-in-instruction"
        as="xs:string">
        <!--
            Some of the elements listed in the match attribute are not strictly needed
            in order to achieve the caller's objective, because the elements have a
            traceable ancestor that would also be a descendant of the element that calls
            this mode. Examples include XSLT:matching-substring, XSLT:non-matching-substring,
            XSLT:merge-*, and XSLT:on-completion. However, it's clearer to list them anyway.
        -->
        <xsl:sequence select="'untraceable executable'"/>
    </xsl:template>

</xsl:stylesheet>