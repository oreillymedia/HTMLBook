<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step xmlns:c="http://www.w3.org/ns/xproc-step" xmlns:impl="urn:x-xspec:compile:impl"
    xmlns:p="http://www.w3.org/ns/xproc" xmlns:xs="http://www.w3.org/2001/XMLSchema" version="3.1"
    type="impl:error-code-attr-to-qname">

    <p:documentation>
        Given a c:errors document that the XProc processor creates when catching
        an error, return the /c:errors/c:error/@code values as xs:QName items.
    </p:documentation>

    <p:input port="source" content-types="xml"/>
    <p:output port="result" content-types="application/json" sequence="true"/>

    <p:variable name="regex-for-NCName" as="xs:string" select="'([\i-[:]][\c-[:]]*)'"/>
    <p:variable name="regex-for-UQName" as="xs:string"
        select="'Q\{([^\{\}]*)\}' || $regex-for-NCName"/>

    <p:filter select="/c:errors/c:error"/>
    <p:for-each>
        <p:variable name="this-error" select="/c:error"/>
        <p:variable name="in-scope-prefixes" select="in-scope-prefixes($this-error)" as="xs:string*"/>
        <p:variable name="code" select="string($this-error/@code)" as="xs:string"/>
        <p:variable name="tokenized" select="tokenize($code, ':')" as="xs:string*"/>
        <!-- Empirically, XML Calabash (v3.0.38) seems to use only unprefixed and unprefixed names,
            so not all the branches of the if/then/else clause come up in practice. -->
        <p:variable name="code-as-QName" as="xs:QName?" select="
            if ($code eq '')
            then ()
            else if (matches($code, $regex-for-UQName) (: URI-qualified name :))
            then QName(replace($code, $regex-for-UQName, '$1'), replace($code, $regex-for-UQName, '$2'))
            else if (count($tokenized) eq 1 and ($code castable as xs:QName) (: Unprefixed :))
            then xs:QName($code)
            else if ((count($tokenized) eq 2) and ($tokenized[1] = $in-scope-prefixes) (: Prefixed :))
            then resolve-QName($code, $this-error)
            else () (: Unrecognized content :)
            "/>
        <p:identity>
            <p:with-input select="$code-as-QName">
                <p:inline/>
            </p:with-input>
        </p:identity>
    </p:for-each>
</p:declare-step>
