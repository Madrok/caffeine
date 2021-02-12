package chx.lang;

import haxe.PosInfos;

class Exception extends haxe.Exception {
	/**
	 * Position where this exception was created.
	 */
	public final posInfos : PosInfos;

	public function new(msg : String = "", ?previous : Exception, ?native : Any, ?pos : PosInfos) {
		super(msg, previous, native);
		if(pos == null) {
			posInfos = {
				fileName : '(unknown)',
				lineNumber : 0,
				className : '(unknown)',
				methodName : '(unknown)'
			}
		}
		else {
			posInfos = pos;
		}
	}

	public override function toString() {
		return Type.getClassName(Type.getClass(this)) + "(" + ((message == null) ? "" : message)
			+
			')  in ${posInfos.className}.${posInfos.methodName} at ${posInfos.fileName} :$ {posInfos.lineNumber}';
	}
}
