<?xml version="1.0" encoding="UTF-8"?>
<!-- Input port:
    Input content is a p:declare-step element created by the XSpec compiler
    corresponding to a particular x:call element and its x:input and
    x:option children. -->
<!-- Options:
    $map-of-inputs is derived from x:input. $map-of-options is derived from x:option.
    Maps help this step accommodate test target steps with arbitrary numbers and names
    of ports and options. Option names become string-valued keys of the form 'simple'
    for option names in the null namespace or 'Q{uri}name' for option names in a
    non-null namespace. -->
<!-- Output port:
    Output is a map with a key named 'ports' that is itself a map.
    The inner map has structure like the following:
        map{
          'output-port1': (
            map{
              'document': document{<svg/>},
              'document-properties': map{QName('', 'content-type'): 'image/svg+xml',...}
            },
            map{
              'document': document{<foo/>},
              'document-properties': map{QName('', 'content-type'): 'application/xml',...}
            }
          ),
          'output-port2': (
            map{
              'document': 0,
              'document-properties': map{QName('', 'content-type'): 'application/json',...}
            }
          )
        }
-->
<p:declare-step xmlns:impl="urn:x-xspec:compile:impl" xmlns:p="http://www.w3.org/ns/xproc"
    type="impl:step-runner" name="step-runner" version="3.1">

    <p:input port="step-to-call-test-target" content-types="application/xml"/>
    <p:output port="map-of-outputs" pipe="map-of-outputs@call-test-target"
        content-types="application/json"/>
    <p:option name="map-of-inputs" as="map(*)"/>
    <p:option name="map-of-options" as="map(*)"/>

    <p:run name="call-test-target">
        <p:with-input pipe="step-to-call-test-target@step-runner"/>
        <p:run-option name="map-of-inputs" select="$map-of-inputs"/>
        <p:run-option name="map-of-options" select="$map-of-options"/>
        <p:output port="map-of-outputs" primary="true"/>
    </p:run>
</p:declare-step>