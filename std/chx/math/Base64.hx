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

package chx.math;

/**
	Allows one to encode/decode String and bytes using Base64 encoding.
**/
class Base64 {
	public static var BYTES(default, null) = chx.ds.Bytes.ofString(Constants.DIGITS_BASE64);
	public static var URL_BYTES(default, null) = chx.ds.Bytes.ofString(Constants.DIGITS_URL_ENCODE);

	/**
	 * Encode Bytes to base64 string
	 * @param bytes 
	 * @param complement = true Add the padding `=` signs to the encoded string
	 * @return String
	 */
	public static function encode(bytes : chx.ds.Bytes, complement = true) : String {
		var str = new BaseCode(BYTES)
			.encodeBytes(bytes)
			.toString();
		if(complement)
			switch(bytes.length % 3) {
				case 1:
					str += "==";
				case 2:
					str += "=";
				default:
			}
		return str;
	}

	/**
	 * Decode a base64 encoded string. 
	 * @param str 
	 * @param complement = true The input string is padded with `=` signs et the end
	 * @return chx.ds.Bytes
	 * @throws chx.lang.FormatException if input string contains improper characters
	 */
	public static function decode(str : String, complement = true) : chx.ds.Bytes {
		if(complement)
			while(str.charCodeAt(str.length - 1) == "=".code)
				str = str.substr(0, -1);
		return new BaseCode(BYTES)
			.decodeBytes(chx.ds.Bytes.ofString(str));
	}

	/**
	 * Url encode bytes. Similar to base64 but uses slightly different characters
	 * @param bytes 
	 * @param complement = false Add the padding `=` signs to the encoded string
	 * @return String
	 */
	public static function urlEncode(bytes : chx.ds.Bytes, complement = false) : String {
		var str = new BaseCode(URL_BYTES)
			.encodeBytes(bytes)
			.toString();
		if(complement)
			switch(bytes.length % 3) {
				case 1:
					str += "==";
				case 2:
					str += "=";
				default:
			}
		return str;
	}

	/**
	 * Decode a URL encoded string
	 * @param str 
	 * @param complement = false The input string is padded with `=` signs et the end
	 * @return chx.ds.Bytes
	 * @throws chx.lang.FormatException if input string contains improper characters
	 */
	public static function urlDecode(str : String, complement = false) : chx.ds.Bytes {
		if(complement)
			while(str.charCodeAt(str.length - 1) == "=".code)
				str = str.substr(0, -1);
		return new BaseCode(URL_BYTES)
			.decodeBytes(chx.ds.Bytes.ofString(str));
	}
}
