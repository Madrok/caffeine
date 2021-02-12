/*
 * Copyright (C)2005-2019 Haxe Foundation
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */

import haxe.Exception;
import haxe.iterators.StringIterator;
import haxe.iterators.StringKeyValueIterator;

#if cpp
using cpp.NativeString;
#end

/**
	This class provides advanced methods on Strings. It is ideally used with
	`using StringTools` and then acts as an [extension](https://haxe.org/manual/lf-static-extension.html)
	to the `String` class.

	If the first argument to any of the methods is null, the result is
	unspecified.
**/
class StringTools {
	/**
		Encode an URL by using the standard format.
	**/
	#if( !java
		&& !cpp
		&& !lua
		&& !eval ) inline #end public static function urlEncode(s : String) : String {
		#if neko
		return untyped new String(_urlEncode(s.__s));
		#elseif js
		return untyped encodeURIComponent(s);
		#elseif cpp
		return untyped s.__URLEncode();
		#elseif java
		return postProcessUrlEncode(java.net.URLEncoder.encode(s, "UTF-8"));
		#elseif cs
		return untyped cs.system.Uri.EscapeDataString(s);
		#elseif python
		return python.lib.urllib.Parse.quote(s, "");
		#elseif hl
		var len = 0;
		var b = @:privateAccess s.bytes.urlEncode(len);
		return @:privateAccess String.__alloc__(b, len);
		#elseif lua
		s = lua.NativeStringTools.gsub(s, "\n", "\r\n");
		s = lua.NativeStringTools.gsub(s, "([^%w %-%_%.%~])", function(c) {
			return lua.NativeStringTools.format("%%%02X", lua.NativeStringTools.byte(c) + '');
		});
		s = lua.NativeStringTools.gsub(s, " ", "+");
		return s;
		#else
		return null;
		#end
	}

	#if java
	private static function postProcessUrlEncode(s : String) : String {
		var ret = new StringBuf();
		var i = 0, len = s.length;
		while(i < len) {
			switch(_charAt(s, i++)) {
				case '+'.code:
					ret.add('%20');
				case '%'.
					code if(i <= len - 2):
					var c1 = _charAt(s, i++), c2 = _charAt(s, i++);
					switch [c1, c2] {
						case ['2'.code, '1'.code]:
							ret.addChar('!'.code);
						case ['2'.code, '7'.code]:
							ret.addChar('\''.code);
						case ['2'.code, '8'.code]:
							ret.addChar('('.code);
						case ['2'.code, '9'.code]:
							ret.addChar(')'.code);
						case ['7'.code, 'E'.code]
							| ['7'.code, 'e'.code]:
							ret.addChar('~'.code);
						case _:
							ret.addChar('%'.code);
							ret.addChar(cast c1);
							ret.addChar(cast c2);
					}
				case var chr:
					ret.addChar(cast chr);
			}
		}
		return ret.toString();
	}
	#end

	/**
		Decode an URL using the standard format.
	**/
	#if( !java
		&& !cpp
		&& !lua
		&& !eval ) inline #end public static function urlDecode(s : String) : String {
		#if neko
		return untyped new String(_urlDecode(s.__s));
		#elseif js
		return untyped decodeURIComponent(s
			.split("+")
			.join(" ")
		);
		#elseif cpp
		return untyped s.__URLDecode();
		#elseif java
		try
			return java.net.URLDecoder.decode(s, "UTF-8")
		catch(e:Dynamic)
			throw e;
		#elseif cs
		return untyped cs.system.Uri.UnescapeDataString(s);
		#elseif python
		return python.lib.urllib.Parse.unquote(s);
		#elseif hl
		var len = 0;
		var b = @:privateAccess s.bytes.urlDecode(len);
		return @:privateAccess String.__alloc__(b, len);
		#elseif lua
		s = lua.NativeStringTools.gsub(s, "+", " ");
		s = lua.NativeStringTools.gsub(s, "%%(%x%x)", function(h) {
			return lua.NativeStringTools.char(lua.Lua.tonumber(h, 16));
		});
		s = lua.NativeStringTools.gsub(s, "\r\n", "\n");
		return s;
		#else
		return null;
		#end
	}

	/**
		Escapes HTML special characters of the string `s`.

		The following replacements are made:

		- `&` becomes `&amp`;
		- `<` becomes `&lt`;
		- `>` becomes `&gt`;

		If `quotes` is true, the following characters are also replaced:

		- `"` becomes `&quot`;
		- `'` becomes `&#039`;
	**/
	public static function htmlEscape(s : String, ?quotes : Bool) : String {
		var buf = new StringBuf();
		for (code in #if neko iterator(s) #else new haxe.iterators.StringIteratorUnicode(s) #end) {
			switch(code) {
				case '&'.code:
					buf.add("&amp;");
				case '<'.code:
					buf.add("&lt;");
				case '>'.code:
					buf.add("&gt;");
				case '"'.
					code if(quotes):
					buf.add("&quot;");
				case '\''.
					code if(quotes):
					buf.add("&#039;");
				case _:
					buf.addChar(code);
			}
		}
		return buf.toString();
	}

	/**
		Unescapes HTML special characters of the string `s`.

		This is the inverse operation to htmlEscape, i.e. the following always
		holds: `htmlUnescape(htmlEscape(s)) == s`

		The replacements follow:

		- `&amp;` becomes `&`
		- `&lt;` becomes `<`
		- `&gt;` becomes `>`
		- `&quot;` becomes `"`
		- `&#039;` becomes `'`
	**/
	public static function htmlUnescape(s : String) : String {
		return s
			.split("&gt;")
			.join(">")
			.split("&lt;")
			.join("<")
			.split("&quot;")
			.join('"')
			.split("&#039;")
			.join("'")
			.split("&amp;")
			.join("&");
	}

	/**
		Returns `true` if `s` contains `value` and  `false` otherwise.

		When `value` is `null`, the result is unspecified.
	**/
	public static inline function contains(s : String, value : String) : Bool {
		#if( js && js_es >= 6 )
		return (cast s)
			.includes(value);
		#else
		return s.indexOf(value) != -1;
		#end
	}

	/**
		Tells if the string `s` starts with the string `start`.

		If `start` is `null`, the result is unspecified.

		If `start` is the empty String `""`, the result is true.
	**/
	public static #if( cs
		|| java
		|| python
		|| (js && js_es >= 6) ) inline #end function startsWith(s : String,
			start : String) : Bool {
		#if java
		return (cast s:java.NativeString)
			.startsWith(start);
		#elseif cs
		return untyped s.StartsWith(start);
		#elseif hl
		return @:privateAccess (s.length >= start.length
			&& s.bytes.compare(0, start.bytes, 0, start.length << 1) == 0);
		#elseif python
		return python.NativeStringTools.startswith(s, start);
		#elseif( js && js_es >= 6 )
		return (cast s)
			.startsWith(start);
		#else
		return (s.length >= start.length && s.lastIndexOf(start, 0) == 0);
		#end
	}

	/**
		Tells if the string `s` ends with the string `end`.

		If `end` is `null`, the result is unspecified.

		If `end` is the empty String `""`, the result is true.
	**/
	public static #if( cs
		|| java
		|| python
		|| (js && js_es >= 6) ) inline #end function endsWith(s : String, end : String) : Bool {
		#if java
		return (cast s:java.NativeString)
			.endsWith(end);
		#elseif cs
		return untyped s.EndsWith(end);
		#elseif hl
		var elen = end.length;
		var slen = s.length;
		return @:privateAccess (slen >= elen
			&& s.bytes.compare((slen - elen) << 1, end.bytes, 0, elen << 1) == 0);
		#elseif python
		return python.NativeStringTools.endswith(s, end);
		#elseif( js && js_es >= 6 )
		return (cast s)
			.endsWith(end);
		#else
		var elen = end.length;
		var slen = s.length;
		return (slen >= elen && s.indexOf(end, (slen - elen)) == (slen - elen));
		#end
	}

	/**
		Tells if the character in the string `s` at position `pos` is a space.

		A character is considered to be a space character if its character code
		is 9,10,11,12,13 or 32.

		If `s` is the empty String `""`, or if pos is not a valid position within
		`s`, the result is false.
	**/
	public static function isSpace(s : String, pos : Int) : Bool {
		#if( python || lua )
		if(s.length == 0 || pos < 0 || pos >= s.length)
			return false;
		#end
		var c = s.charCodeAt(pos);
		return (c > 8 && c < 14) || c == 32;
	}

	/**
		Removes leading space characters of `s`.

		This function internally calls `isSpace()` to decide which characters to
		remove.

		If `s` is the empty String `""` or consists only of space characters, the
		result is the empty String `""`.
	**/
	public #if cs inline #end static function ltrim(s : String) : String {
		#if cs
		return untyped s.TrimStart();
		#else
		var l = s.length;
		var r = 0;
		while(r < l && isSpace(s, r)) {
			r++;
		}
		if(r > 0)
			return s.substr(r, l - r);
		else
			return s;
		#end
	}

	/**
		Removes trailing space characters of `s`.

		This function internally calls `isSpace()` to decide which characters to
		remove.

		If `s` is the empty String `""` or consists only of space characters, the
		result is the empty String `""`.
	**/
	public #if cs inline #end static function rtrim(s : String) : String {
		#if cs
		return untyped s.TrimEnd();
		#else
		var l = s.length;
		var r = 0;
		while(r < l && isSpace(s, l - r - 1)) {
			r++;
		}
		if(r > 0) {
			return s.substr(0, l - r);
		}
		else {
			return s;
		}
		#end
	}

	/**
		Removes leading and trailing space characters of `s`.

		This is a convenience function for `ltrim(rtrim(s))`.
	**/
	public #if( cs || java ) inline #end static function trim(s : String) : String {
		#if cs
		return untyped s.Trim();
		#elseif java
		return (cast s:java.NativeString)
			.trim();
		#else
		return ltrim(rtrim(s));
		#end
	}

	/**
		Concatenates `c` to `s` until `s.length` is at least `l`.

		If `c` is the empty String `""` or if `l` does not exceed `s.length`,
		`s` is returned unchanged.

		If `c.length` is 1, the resulting String length is exactly `l`.

		Otherwise the length may exceed `l`.

		If `c` is null, the result is unspecified.
	**/
	public static function lpad(s : String, c : String, l : Int) : String {
		if(c.length <= 0)
			return s;

		var buf = new StringBuf();
		l -= s.length;
		while(buf.length < l) {
			buf.add(c);
		}
		buf.add(s);
		return buf.toString();
	}

	/**
		Appends `c` to `s` until `s.length` is at least `l`.

		If `c` is the empty String `""` or if `l` does not exceed `s.length`,
		`s` is returned unchanged.

		If `c.length` is 1, the resulting String length is exactly `l`.

		Otherwise the length may exceed `l`.

		If `c` is null, the result is unspecified.
	**/
	public static function rpad(s : String, c : String, l : Int) : String {
		if(c.length <= 0)
			return s;

		var buf = new StringBuf();
		buf.add(s);
		while(buf.length < l) {
			buf.add(c);
		}
		return buf.toString();
	}

	/**
		Replace all occurrences of the String `sub` in the String `s` by the
		String `by`.

		If `sub` is the empty String `""`, `by` is inserted after each character
		of `s` except the last one. If `by` is also the empty String `""`, `s`
		remains unchanged.

		If `sub` or `by` are null, the result is unspecified.
	**/
	public static function replace(s : String, sub : String, by : String) : String {
		#if java
		if(sub.length == 0)
			return s
				.split(sub)
				.join(by);
		else
			return (cast s:java.NativeString)
				.replace(sub, by);
		#elseif cs
		if(sub.length == 0)
			return s
				.split(sub)
				.join(by);
		else
			return untyped s.Replace(sub, by);
		#else
		return s
			.split(sub)
			.join(by);
		#end
	}

	/**
		Encodes `n` into a hexadecimal representation.

		If `digits` is specified, the resulting String is padded with "0" until
		its `length` equals `digits`.
	**/
	public static function hex(n : Int, ?digits : Int) {
		var s = "";
		var hexChars = "0123456789ABCDEF";
		do {
			s = hexChars.charAt(n & 15) + s;
			n >>>= 4;
		}
		while(n > 0);
		#if python
		if(digits != null && s.length < digits) {
			var diff = digits - s.length;
			for (_ in 0...diff) {
				s = "0" + s;
			}
		}
		#else
		if(digits != null)
			while(s.length < digits)
				s = "0" + s;
		#end
		return s;
	}

	/**
		Returns the character code at position `index` of String `s`, or an
		end-of-file indicator at if `position` equals `s.length`.

		This method is faster than `String.charCodeAt()` on some platforms, but
		the result is unspecified if `index` is negative or greater than
		`s.length`.

		End of file status can be checked by calling `StringTools.isEof()` with
		the returned value as argument.

		This operation is not guaranteed to work if `s` contains the `\0`
		character.
	**/
	public static #if !eval inline #end function fastCodeAt(s : String, index : Int) : Int {
		#if neko
		return untyped __dollar__sget(s.__s, index);
		#elseif cpp
		return untyped s.cca(index);
		#elseif java
		return (index < s.length) ? cast(_charAt(s, index), Int) : -1;
		#elseif cs
		return (cast(index, UInt) < s.length) ? cast(s[index], Int) : -1;
		#elseif js
		return (cast s)
			.charCodeAt(index);
		#elseif python
		return if(index >= s.length)-1 else
			python.internal.UBuiltins.ord(python.Syntax.arrayAccess(s, index));
		#elseif hl
		return @:privateAccess s.bytes.getUI16(index << 1);
		#elseif lua
		#if lua_vanilla
		return lua.NativeStringTools.byte(s, index + 1);
		#else
		return lua.lib.luautf8.Utf8.byte(s, index + 1);
		#end
		#else
		return untyped s.cca(index);
		#end
	}

	/**
		Returns the character code at position `index` of String `s`, or an
		end-of-file indicator at if `position` equals `s.length`.

		This method is faster than `String.charCodeAt()` on some platforms, but
		the result is unspecified if `index` is negative or greater than
		`s.length`.

		This operation is not guaranteed to work if `s` contains the `\0`
		character.
	**/
	public static #if !eval inline #end function unsafeCodeAt(s : String, index : Int) : Int {
		#if neko
		return untyped __dollar__sget(s.__s, index);
		#elseif cpp
		return untyped s.cca(index);
		#elseif java
		return cast(_charAt(s, index), Int);
		#elseif cs
		return cast(s[index], Int);
		#elseif js
		return (cast s)
			.charCodeAt(index);
		#elseif python
		return python.internal.UBuiltins.ord(python.Syntax.arrayAccess(s, index));
		#elseif hl
		return @:privateAccess s.bytes.getUI16(index << 1);
		#elseif lua
		#if lua_vanilla
		return lua.NativeStringTools.byte(s, index + 1);
		#else
		return lua.lib.luautf8.Utf8.byte(s, index + 1);
		#end
		#else
		return untyped s.cca(index);
		#end
	}

	/**
		Returns an iterator of the char codes.

		Note that char codes may differ across platforms because of different
		internal encoding of strings in different runtimes.
		For the consistent cross-platform UTF8 char codes see `haxe.iterators.StringIteratorUnicode`.
	**/
	public static inline function iterator(s : String) : StringIterator {
		return new StringIterator(s);
	}

	/**
		Returns an iterator of the char indexes and codes.

		Note that char codes may differ across platforms because of different
		internal encoding of strings in different of runtimes.
		For the consistent cross-platform UTF8 char codes see `haxe.iterators.StringKeyValueIteratorUnicode`.
	**/
	public static inline function keyValueIterator(s : String) : StringKeyValueIterator {
		return new StringKeyValueIterator(s);
	}

	/**
		Tells if `c` represents the end-of-file (EOF) character.
	**/
	@:noUsing public static inline function isEof(c : Int) : Bool {
		#if( cpp || hl )
		return c == 0;
		#elseif js
		return c != c; // fast NaN
		#elseif( neko || lua || eval )
		return c == null;
		#elseif( cs || java || python )
		return c == -1;
		#else
		return false;
		#end
	}

	/**
	 * Splits a string by lines, either \n or \r\n
	 * @param str any string to split
	 * @return Array<String> array of strings plit by lines
	 */
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

	/**
	 * Tells if the character in the string [s] at position [pos] is a decimal number (0-9).
	 * @param s 
	 * @param pos 
	 * @return Bool
	 */
	public static function isNum(s : String, pos : Int) : Bool {
		var c = s.charCodeAt(pos);
		return (c >= 48 && c <= 57);
	}

	/**
	 * Tells if the character in the string [s] at position [pos] is a alpha char (A-Z a-z).
	 * @param s 
	 * @param pos 
	 * @return Bool true if is alpha
	 */
	public static function isAlpha(s : String, pos : Int) : Bool {
		var c = s.charCodeAt(pos);
		return (c >= 65 && c <= 90) || (c >= 97 && c <= 122);
	}

	/**
	 * Returns the decimal number from string [s] at position [pos] or null if it is not a decimal number (0-9)
	 * @param s 
	 * @param pos 
	 * @return Null<Int>
	 */
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

	/**
	 * Strip whitespace out of a string, without using regular expressions
	 * @param s 
	 * @return String
	 */
	public static function stripWhite(s : String) : String {
		var l = s.length;
		var i = 0;
		var sb = new StringBuf();
		while(i < l) {
			if(!isSpace(s, i))
				sb.add(s.charAt(i));
			i++;
		}
		return sb.toString();
	}

	/**
	 * Continues to replace [sub] with [by] until no more instances of [sub] exist.
	 * @param s Original string
	 * @param sub Pattern of characters to be replaced 
	 * @param by Replacement string
	 * @return String
	 * @throws chx.lang.Exception if the replacement would lead to infinite recursion
	 */
	public static function replaceRecurse(s : String, sub : String, by : String) : String {
		if(sub.length == 0)
			return replace(s, sub, by);
		if(by.indexOf(sub) >= 0)
			throw new chx.lang.Exception("Infinite recursion");
		var ns : String = Std.string(s);
		var olen = 0;
		var nlen = ns.length;
		while(olen != nlen) {
			olen = ns.length;
			replace(ns, sub, by);
			nlen = ns.length;
		}
		return ns;
	}

	#if java
	private static inline function _charAt(str : String, idx : Int) : java.StdTypes.Char16
		return (cast str:java.NativeString)
			.charAt(idx);
	#end

	#if neko
	private static var _urlEncode = neko.Lib.load("std", "url_encode", 1);
	private static var _urlDecode = neko.Lib.load("std", "url_decode", 1);
	#end

	#if utf16
	static inline var MIN_SURROGATE_CODE_POINT = 65536;

	static inline function utf16CodePointAt(s : String, index : Int) : Int {
		var c = StringTools.fastCodeAt(s, index);
		if(c >= 0xD800 && c <= 0xDBFF) {
			c = ((c - 0xD7C0) << 10) | (StringTools.fastCodeAt(s, index + 1) & 0x3FF);
		}
		return c;
	}
	#end
}