package chx.lang;

class Exception extends haxe.Exception {
	public function new(msg : String = "", ?previous : Exception, ?native : Any) {
		super(msg, previous, native);
	}

	public override function toString() {
		return Type.getClassName(Type.getClass(this)) + "("
			+ if(message == null)"" else message + ")";
	}
}
