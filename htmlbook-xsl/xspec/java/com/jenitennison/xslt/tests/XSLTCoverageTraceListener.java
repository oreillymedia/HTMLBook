/****************************************************************************/
/*  File:       XSLTCoverageTraceListener.java                              */
/*  Author:     Jeni Tennison                                               */
/*  URI:        https://github.com/xspec/xspec/                             */
/*  Tags:                                                                   */
/*  Copyright (c) 2008-2016 (see end of file.)                              */
/* ------------------------------------------------------------------------ */


package com.jenitennison.xslt.tests;

import java.io.File;
import java.net.URI;
import java.net.URISyntaxException;
import java.util.HashMap;
import java.util.Map;

import javax.xml.stream.XMLStreamException;

import net.sf.saxon.Controller;
import net.sf.saxon.event.StreamWriterToReceiver;
import net.sf.saxon.expr.Component;
import net.sf.saxon.expr.XPathContext;
import net.sf.saxon.expr.instruct.Actor;
import net.sf.saxon.expr.instruct.Instruction;
import net.sf.saxon.expr.instruct.TemplateRule;
import net.sf.saxon.expr.parser.XPathParser;
import net.sf.saxon.functions.ResolveURI;
import net.sf.saxon.lib.Logger;
import net.sf.saxon.lib.TraceListener;
import net.sf.saxon.om.Item;
import net.sf.saxon.om.StandardNames;
import net.sf.saxon.om.StructuredQName;
import net.sf.saxon.s9api.Location;
import net.sf.saxon.s9api.Processor;
import net.sf.saxon.s9api.SaxonApiException;
import net.sf.saxon.s9api.Serializer;
import net.sf.saxon.trace.Traceable;
import net.sf.saxon.tree.AttributeLocation;

/**
 * A Simple trace listener for XSLT that writes messages to XML file
 */

public class XSLTCoverageTraceListener implements TraceListener {

  private int openCount = 0;
  private String xspecStylesheet = null;
  private HashMap<String, Integer> utils = new HashMap<String, Integer>();
  private HashMap<String, Integer> modules = new HashMap<String, Integer>();
  private HashMap<String, Integer> traceables = new HashMap<String, Integer>();
  private int utilsCount = 0;
  private int moduleCount = 0;
  private int traceableCount = 0;
  private StreamWriterToReceiver writer = null;
  private String srcDir = null;
  private String ignoreDir = null;
  private boolean debugPrintEnabled = (System.getenv("DEBUG_XSLT_COVERAGE_TRACE_LISTENER") != null);

  private void debugPrintf(String format, Object... args) {
    if (debugPrintEnabled) {
      System.err.printf(format, args);
    }
  }

  private URI filePathToUri(String filePath) {
    File f = new File(filePath);
    return f.toURI();
  }

  public XSLTCoverageTraceListener() {
    System.out.println("****************************************");
  }

  /**
   * Method called at the start of execution, that is, when the run-time transformation starts
   * @param c Controller used
   */

  public void open(Controller c) {
    System.out.println("controller="+c);

    openCount++;
    if (openCount >= 2) {
      // Re-entered. Maybe by transform().
      return;
    }

    // Get the URI of XSpec home
    URI xspecHomeUri;
    String xspecHomeUriProp = System.getProperty("xspec.home.uri");
    if (xspecHomeUriProp == null) {
      String xspecHomeProp = System.getProperty("xspec.home");
      debugPrintf("%-17s: %s%n", "xspec.home", xspecHomeProp);

      xspecHomeUri = filePathToUri(xspecHomeProp + File.separator);
    }
    else {
      debugPrintf("%-17s: %s%n", "xspec.home.uri", xspecHomeUriProp);
      try {
        xspecHomeUri = new URI(xspecHomeUriProp);
      } catch (URISyntaxException e) {
        throw new RuntimeException(e);
      }
    }
    debugPrintf("%-17s: %s%n", "xspecHomeUri", xspecHomeUri);

    // Get 'src/' URI and normalize it
    try {
        // Use net.sf.saxon.functions.ResolveURI#makeAbsolute, because
        // java.net.URI#resolve cannot handle "jar:" scheme.
        srcDir = ResolveURI.makeAbsolute("src/", xspecHomeUri.toString()).normalize().toString();
    } catch (URISyntaxException e) {
        throw new RuntimeException(e);
    }
    debugPrintf("%-17s: %s%n", "srcDir", srcDir);

    // Get the directory path to ignore
    ignoreDir = System.getProperty("xspec.coverage.ignore");
    debugPrintf("%-17s: %s%n", "ignoreDir (raw)", ignoreDir);

    // Normalize the directory as URI
    ignoreDir = filePathToUri(ignoreDir + File.separator).normalize().toString();
    debugPrintf("%-17s: %s%n", "ignoreDir (norm)", ignoreDir);

    // Coverage XML file
    String outPath = System.getProperty("xspec.coverage.xml");
    File outFile = new File(outPath);

    // XSpec file
    String xspecPath = System.getProperty("xspec.xspecfile");
    xspecPath = filePathToUri(xspecPath).toString();

    Serializer serializer = new Processor(false).newSerializer(outFile);
    serializer.setOutputProperty(Serializer.Property.INDENT, "yes");

    try {
      writer = serializer.getXMLStreamWriter();
    } catch(SaxonApiException e) {
      throw new RuntimeException(e);
    }

    try {
      writer.writeStartDocument();
      writer.writeStartElement("trace");
      writer.writeAttribute("xspec", xspecPath);
    } catch(XMLStreamException e) {
      throw new RuntimeException(e);
    }
  }

  /**  
   * Method that implements the output destination
   */
  public void setOutputDestination(Logger logger) {
    // Do nothing
  }

  /**
  * Method called at the end of execution, that is, when the run-time execution ends
  */
  public void close() {
    openCount--;
    if (openCount >= 1) {
      return;
    }

    try {
      writer.writeEndElement(); // </trace>
      writer.writeEndDocument();
      writer.close();
    } catch(XMLStreamException e) {
      throw new RuntimeException(e);
    }
  }

  /**
   * Method that is called when an instruction in the stylesheet gets processed.
   * @param context XPath context used
   */

  public void enter(Traceable traceable, Map<String, Object> properties, XPathContext context) {
    Location location = getLocation(traceable);
    int lineNumber = location.getLineNumber();
    int columnNumber = location.getColumnNumber();

    // Get the current file URI
    String systemId = location.getSystemId();
    debugPrintf("%-17s: %s:%d:%d%n", "enter()", systemId, lineNumber, columnNumber);

    // Normalize the current file URI
    URI systemIdUri;
    try {
      systemIdUri = new URI(systemId);
    } catch (URISyntaxException e) {
      throw new RuntimeException(e);
    }
    systemId = systemIdUri.normalize().toString();
    debugPrintf("%-17s: %s%n", "systemId (norm)", systemId);
    
    boolean isUtil = false;

    if (systemId.startsWith(srcDir)) {
      isUtil = true;

      if (!utils.containsKey(systemId)) {
        Integer utilId = Integer.valueOf(utilsCount);
        debugPrintf(
          "%-17s: %s%n",
          "util[" + utilId + "]",
          systemId
        );

        utilsCount++;
        utils.put(systemId, utilId);

        try {
          writer.writeStartElement("util");
          writer.writeAttribute("utilId", String.valueOf(utilId));
          writer.writeAttribute("uri", systemId);
          writer.writeEndElement();
        } catch(XMLStreamException e) {
          throw new RuntimeException(e);
        }
      }
    } else if (xspecStylesheet == null && 
               systemId.startsWith(ignoreDir)) {
      xspecStylesheet = systemId;
      debugPrintf("%-17s: %s%n", "xspecStylesheet", xspecStylesheet);

      try {
        writer.writeStartElement("compiled");
        writer.writeAttribute("uri", systemId);
        writer.writeEndElement();
      } catch(XMLStreamException e) {
        throw new RuntimeException(e);
      }
    } 

    if (systemId != xspecStylesheet && !isUtil) {
      Integer moduleId;
      if (modules.containsKey(systemId)) {
        moduleId = (Integer)modules.get(systemId);
      } else {
        moduleId = Integer.valueOf(moduleCount);
        moduleCount += 1;
        modules.put(systemId, moduleId);

        try {
          writer.writeStartElement("module");
          writer.writeAttribute("moduleId", String.valueOf(moduleId));
          writer.writeAttribute("uri", systemId);
          writer.writeEndElement();
        } catch(XMLStreamException e) {
          throw new RuntimeException(e);
        }
      }

      String traceableClassName = traceable.getClass().getName();
      Integer traceableId;

      if (traceables.containsKey(traceableClassName)) {
        traceableId = (Integer) traceables.get(traceableClassName);
      }
      else {
        traceableId = traceableCount;
        traceableCount++;
        traceables.put(traceableClassName, traceableId);

        String traceableUQName = null;
        int traceableFingerprint = -1;
        if (traceable instanceof Actor) {
          Component declaringComponent = ((Actor) traceable).getDeclaringComponent();
          traceableFingerprint = declaringComponent.getComponentKind();
        }
        else if (traceable instanceof Instruction) {
          traceableFingerprint = ((Instruction) traceable).getInstructionNameCode();
        }
        else if (traceable instanceof TemplateRule) {
          traceableFingerprint = ((TemplateRule) traceable).getComponentKind();
        }

        if ((0 <= traceableFingerprint) && (traceableFingerprint <= 1023)) {
          StructuredQName traceableStructuredQName = StandardNames.getUnprefixedQName(traceableFingerprint);
          traceableUQName = traceableStructuredQName.getEQName();
        }

        try {
          writer.writeStartElement("traceable");
          writer.writeAttribute("traceableId", traceableId.toString());
          if (traceableClassName != null) {
            writer.writeAttribute("class", traceableClassName);
          }
          if (traceableUQName != null) {
            // Note: traceableUQName is sometimes an ancestor of the
            // node coverage-report.xsl expects to see (#1917).
            writer.writeAttribute("uqname", traceableUQName);
          }
          writer.writeEndElement();
        } catch(XMLStreamException e) {
          throw new RuntimeException(e);
        }
      }

      try {
        writer.writeStartElement("hit");
        writer.writeAttribute("lineNumber", String.valueOf(lineNumber));
        writer.writeAttribute("columnNumber", String.valueOf(columnNumber));
        writer.writeAttribute("moduleId", String.valueOf(moduleId));
        writer.writeAttribute("traceableId", traceableId.toString());
        writer.writeEndElement();
      } catch(XMLStreamException e) {
        throw new RuntimeException(e);
      }
    }
  }

  /* getLocation method introduced in Saxon 12.5 */
  /**
   * Get the location information for the traceble expression or instruction.
   * This method adjusts the location for XPath expressions contained in attributes
   * of XSLT instructions, to give the location of the containing element, which
   * supplies a simple line number and column number.
   * @param info the traceable whose location is required
   * @return a sanitised Location object
   */
  public static Location getLocation(Traceable info) {
    Location rawLocation = info.getLocation();
    if (rawLocation instanceof XPathParser.NestedLocation) {
      Location container = ((XPathParser.NestedLocation)rawLocation).getContainingLocation();
      if (container instanceof AttributeLocation) {
        return container;
      }
    }
    return rawLocation;
  }

  /**
   * Method that is called by an instruction that changes the current item
   * in the source document: that is, xsl:for-each, xsl:apply-templates, xsl:for-each-group.
   * The method is called after the enter method for the relevant instruction, and is called
   * once for each item processed.
   * @param currentItem the new current item. Item objects are not mutable; it is safe to retain
   * a reference to the Item for later use.
   */

  public void startCurrentItem(Item currentItem) {
    // Do nothing
  }

  /**
   * Method that is called when an instruction has finished processing a new current item
   * and is ready to select a new current item or revert to the previous current item.
   * The method will be called before the leave() method for the instruction that made this
   * item current.
   * @param currentItem the item that was current, whose processing is now complete. This will represent
   * the same underlying item as the corresponding startCurrentItem() call, though it will
   * not necessarily be the same actual object.
   */

  public void endCurrentItem(Item currentItem) {
    // Do nothing
  }

}


//
// The contents of this file are subject to the Mozilla Public License
// Version 1.0 (the "License"); you may not use this file except in
// compliance with the License. You may obtain a copy of the License
// at http://www.mozilla.org/MPL/
//
// Software distributed under the License is distributed on an "AS IS"
// basis, WITHOUT WARRANTY OF ANY KIND, either express or implied.
// See the License for the specific language governing rights and
// limitations under the License.
//
// The Original Code is: all this file.
//
// The Initial Developer of the Original Code is Edwin Glaser
// (edwin@pannenleiter.de)
//
// Portions created by Jeni Tennison are Copyright (C) Jeni Tennison.
// All Rights Reserved.
//
// Contributor(s): Heavily modified by Michael Kay
//                 Methods implemented by Jeni Tennison
//                 Extended for Saxon 9.7 by Sandro Cirulli, github.com/cirulls
