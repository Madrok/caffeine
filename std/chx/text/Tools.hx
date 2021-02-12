package chx.text;

class Tools {
	public static function octal(n : Int, ?digits : Int) {
		#if flash9
		var n : UInt = n;
		var s : String = untyped n.toString(8);
		#else
		var s = "";
		var octChars = "01234567";
		do {
			s = octChars.charAt(n & 7) + s;
			n >>>= 3;
		}
		while(n > 0);
		#end
		if(digits != null)
			while(s.length < digits)
				s = "0" + s;
		return s;
	}

	/**
		Continues to replace [sub] with [by] until no more instances of [sub] exist.
	**/
	public static function replaceRecurse(s : String, sub : String, by : String) : String {
		if(sub.length == 0)
			return StringTools.replace(s, sub, by);
		if(by.indexOf(sub) >= 0)
			throw "Infinite recursion";
		var ns : String = Std.string(s);
		var olen = 0;
		var nlen = ns.length;
		while(olen != nlen) {
			olen = ns.length;
			StringTools.replace(ns, sub, by);
			nlen = ns.length;
		}
		return ns;
	}

	/**
		Strip whitespace out of a string
	**/
	public static function stripWhite(s : String) : String {
		var l = s.length;
		var i = 0;
		var sb = new StringBuf();
		while(i < l) {
			if(!StringTools.isSpace(s, i))
				sb.add(s.charAt(i));
			i++;
		}
		return sb.toString();
	}

	/**
		Tells if the character in the string [s] at position [pos] is a decimal number (0-9).
	**/
	public static function isNum(s : String, pos : Int) : Bool {
		var c = s.charCodeAt(pos);
		return (c >= 48 && c <= 57);
	}

	/**
		Tells if the character in the string [s] at position [pos] is a alpha char (A-Z a-z).
	**/
	public static function isAlpha(s : String, pos : Int) : Bool {
		var c = s.charCodeAt(pos);
		return (c >= 65 && c <= 90) || (c >= 97 && c <= 122);
	}

	/**
		Returns the decimal number from string [s] at position [pos] or null if it is not a decimal number (0-9)
	**/
	public static function num(s : String, pos : Int) : Null<Int> {
		var c = s.charCodeAt(pos);
		if(c > 0) {
			c -= 48;
			if(c < 0 || c > 9)
				return null;
			return c;
		}
		return null;
	}

	public static function splitLines(str : String) : Array<String> {
		var ret = str.split("\n");
		for (i in 0...ret.length) {
			var l = ret[i];
			if(l.substr(-1, 1) == "\r") {
				ret[i] = l.substr(0, -1);
			}
		}
		return ret;
	}
}
