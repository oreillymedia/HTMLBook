package io.xspec.xspec.saxon.funcdefs;

import net.sf.saxon.expr.XPathContext;
import net.sf.saxon.lib.ExtensionFunctionCall;
import net.sf.saxon.lib.ExtensionFunctionDefinition;
import net.sf.saxon.om.NodeInfo;
import net.sf.saxon.om.Sequence;
import net.sf.saxon.om.StructuredQName;
import net.sf.saxon.trans.XPathException;
import net.sf.saxon.value.Int64Value;
import net.sf.saxon.value.SequenceType;

public class ColumnNumber extends ExtensionFunctionDefinition {

	@Override
	public StructuredQName getFunctionQName() {
		return new StructuredQName("x", "http://www.jenitennison.com/xslt/xspec", "column-number");
	}

	@Override
	public SequenceType[] getArgumentTypes() {
		return new SequenceType[]{SequenceType.SINGLE_NODE};
	}

	@Override
	public SequenceType getResultType(SequenceType[] suppliedArgumentTypes) {
		return SequenceType.SINGLE_INTEGER;
	}

	@Override
	public ExtensionFunctionCall makeCallExpression() {
		return new ExtensionFunctionCall() {
			@Override
			public Sequence call(XPathContext context, Sequence[] arguments) throws XPathException {
				NodeInfo ni = (NodeInfo) arguments[0].head();
				int column = (ni == null) ? -1 : ni.getColumnNumber();
				return Int64Value.makeIntegerValue(column);
			}
		};
	}

}
