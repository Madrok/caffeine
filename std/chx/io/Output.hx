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

/*
 * Copyright (c) 2021, The Caffeine project contributors
 * All rights reserved.
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *   - Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 *   - Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE CAFFEINE PROJECT CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE CAFFEINE PROJECT CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
 * THE POSSIBILITY OF SUCH DAMAGE.
 */
package chx.io;

import chx.ds.Bytes;
import chx.lang.BlockedException;
import chx.lang.EofException;
import chx.lang.OutsideBoundsException;
import chx.lang.OverflowException;
import chx.text.Sprintf;
import chx.vm.Lock;

/**
	An Output is an abstract write. A specific output implementation will only
	have to override the `writeByte` and maybe the `write`, `flush` and `close`
	methods. See `File.write` and `String.write` for two ways of creating an
	Output.
**/
abstract class Output implements IOutput {
	/** A chx.vm.Lock may be added to the Output and available for use **/
	public var lock : Lock;

	/**
		Endianness (word byte order) used when writing numbers.

		If `true`, big-endian is used, otherwise `little-endian` is used.
	**/
	public var bigEndian(default, set) : Bool;

	#if java
	private var helper : java.nio.ByteBuffer;
	#end

	/**
		Write one byte.
	**/
	abstract public function writeByte(c : Int) : Void;

	/**
		Write `len` bytes from `s` starting by position specified by `pos`.

		Returns the actual length of written data that can differ from `len`.

		See `writeFullBytes` that tries to write the exact amount of specified bytes.
	**/
	public function writeBytes(s : Bytes, pos : Int, len : Int) : Int {
		#if !neko
		if(pos < 0 || len < 0 || pos + len > s.length)
			throw new OutsideBoundsException();
		#end
		var b = #if js @:privateAccess s.b #else s.getData() #end;
		var k = len;
		while(k > 0) {
			#if neko
			writeByte(untyped __dollar__sget(b, pos));
			#elseif php
			writeByte(b.get(pos));
			#elseif cpp
			writeByte(untyped b[pos]);
			#elseif hl
			writeByte(b[pos]);
			#else
			writeByte(untyped b[pos]);
			#end
			pos++;
			k--;
		}
		return len;
	}

	/**
		Flush any buffered data.
	**/
	public function flush() {}

	/**
		Close the output.

		Behaviour while writing after calling this method is unspecified.
	**/
	public function close() {}

	function set_bigEndian(b) {
		bigEndian = b;
		return b;
	}

	/* ------------------ API ------------------ */
	/**
		Write all bytes stored in `s`.
	**/
	public function write(s : Bytes) : Void {
		var l = s.length;
		var p = 0;
		while(l > 0) {
			var k = writeBytes(s, p, l);
			if(k == 0)
				throw new BlockedException();
			p += k;
			l -= k;
		}
	}

	/**
		Write `len` bytes from `s` starting by position specified by `pos`.

		Unlike `writeBytes`, this method tries to write the exact `len` amount of bytes.
	**/
	public function writeFullBytes(s : Bytes, pos : Int, len : Int) {
		while(len > 0) {
			var k = writeBytes(s, pos, len);
			pos += k;
			len -= k;
		}
	}

	/**
		Write `x` as 32-bit floating point number.

		Endianness is specified by the `bigEndian` property.
	**/
	public function writeFloat(x : Float) {
		writeInt32(haxe.io.FPHelper.floatToI32(x));
	}

	/**
		Write `x` as 64-bit double-precision floating point number.

		Endianness is specified by the `bigEndian` property.
	**/
	public function writeDouble(x : Float) {
		var i64 = haxe.io.FPHelper.doubleToI64(x);
		if(bigEndian) {
			writeInt32(i64.high);
			writeInt32(i64.low);
		}
		else {
			writeInt32(i64.low);
			writeInt32(i64.high);
		}
	}

	/**
		Write `x` as 8-bit signed integer.
	**/
	public function writeInt8(x : Int) {
		if(x < -0x80 || x >= 0x80)
			throw new OverflowException();
		writeByte(x & 0xFF);
	}

	/**
	 * Writes 
	 * @param x 
	 */
	public function writeUInt8(x : Int) {
		if(x > 0xFF || x < 0)
			throw new OverflowException();
		writeByte(x & 0xFF);
	}

	/**
		Write `x` as 16-bit signed integer.

		Endianness is specified by the `bigEndian` property.
	**/
	public function writeInt16(x : Int) {
		if(x < -0x8000 || x >= 0x8000)
			throw new OverflowException();
		writeUInt16(x & 0xFFFF);
	}

	/**
		Write `x` as 16-bit unsigned integer.

		Endianness is specified by the `bigEndian` property.
	**/
	public function writeUInt16(x : Int) {
		if(x < 0 || x >= 0x10000)
			throw new OverflowException();
		if(bigEndian) {
			writeByte(x >> 8);
			writeByte(x & 0xFF);
		}
		else {
			writeByte(x & 0xFF);
			writeByte(x >> 8);
		}
	}

	/**
		Write `x` as 24-bit signed integer.

		Endianness is specified by the `bigEndian` property.
	**/
	public function writeInt24(x : Int) {
		if(x < -0x800000 || x >= 0x800000)
			throw new OverflowException();
		writeUInt24(x & 0xFFFFFF);
	}

	/**
		Write `x` as 24-bit unsigned integer.

		Endianness is specified by the `bigEndian` property.
	**/
	public function writeUInt24(x : Int) {
		if(x < 0 || x >= 0x1000000)
			throw new OverflowException();
		if(bigEndian) {
			writeByte(x >> 16);
			writeByte((x >> 8) & 0xFF);
			writeByte(x & 0xFF);
		}
		else {
			writeByte(x & 0xFF);
			writeByte((x >> 8) & 0xFF);
			writeByte(x >> 16);
		}
	}

	/**
		Write `x` as 32-bit signed integer.

		Endianness is specified by the `bigEndian` property.
	**/
	public function writeInt32(x : Int) {
		if(bigEndian) {
			writeByte(x >>> 24);
			writeByte((x >> 16) & 0xFF);
			writeByte((x >> 8) & 0xFF);
			writeByte(x & 0xFF);
		}
		else {
			writeByte(x & 0xFF);
			writeByte((x >> 8) & 0xFF);
			writeByte((x >> 16) & 0xFF);
			writeByte(x >>> 24);
		}
	}

	/**
		Inform that we are about to write at least `nbytes` bytes.

		The underlying implementation can allocate proper working space depending
		on this information, or simply ignore it. This is not a mandatory call
		but a tip and is only used in some specific cases.
	**/
	public function prepare(nbytes : Int) {}

	/**
		Read all available data from `i` and write it.

		The `bufsize` optional argument specifies the size of chunks by
		which data is read and written. Its default value is 4096.
	**/
	public function writeInput(i : Input, ?bufsize : Int) {
		if(bufsize == null)
			bufsize = 4096;
		var buf = Bytes.alloc(bufsize);
		try {
			while(true) {
				var len = i.readBytes(buf, 0, bufsize);
				if(len == 0)
					throw new BlockedException();
				var p = 0;
				while(len > 0) {
					var k = writeBytes(buf, p, len);
					if(k == 0)
						throw new BlockedException();
					p += k;
					len -= k;
				}
			}
		}
		catch(e:EofException) {}
	}

	/**
		Write `s` string.
	**/
	public function writeString(s : String, ?encoding : Encoding) {
		#if neko
		var b = untyped new Bytes(s.length, s.__s);
		#else
		var b = Bytes.ofString(s, encoding);
		#end
		writeFullBytes(b, 0, b.length);
	}

	/**
	 * Write a variable length encoded unsigned integer.
	 * @param value the value to encode
	 */
	public function writeLeb128U(value : Int) {
		var byte = 0;

		do {
			byte = value & 0x7F;
			value >>= 7;
			if(value != 0)
				byte |= 0x80;

			writeByte(byte);
		}
		while(value != 0);
	}

	/**
	 * Write a variable length encoded signed integer.
	 * @param value the value to encode
	 */
	public function writeLeb128(value : Int) {
		var byte = 0;

		while(true) {
			byte = value & 0x7F;
			value >>= 7;

			if((value == 0 && byte & 0x40 == 0) || (value == -1 && byte & 0x40 != 0)) {
				writeByte(byte);
				break;
			}
			else {
				byte |= 0x80;
			}

			writeByte(byte);
		}
	}

	/**
	 * Write a LEB128 integer length, then the string. This simplifies
	 * input reading in binary streams.
	 * @param s The string to be written to the stream
	 * @return Output
	 */
	public function writeUTF16String(s : String) : Output {
		var b = Bytes.ofString(s);
		writeLeb128U(b.length);
		writeFullBytes(b, 0, b.length);
		return this;
	}

	/**
	 * Write a boolean to the stream. Represented as a 0 or 1
	 * @param v true or false
	 */
	public function writeBool(v : Bool) : Void {
		writeByte(v ? 1 : 0);
	}

	/**
	 * Writes a formatted string in the printf style.
	 * @see chx.text.Sprintf
	 * @param	format printf() compatible format
	 * @param	args arguments to substitute into format
	 * @param	prependLength set to true to use writeUTF() method
	 * @return this output stream
	 */
	public function printf(format : String, args : Array<Dynamic> = null,
			prependLength : Bool = false) : Output {
		var s = Sprintf.format(format, args);
		if(prependLength) {
			writeUTF16String(s);
		}
		else {
			writeString(s);
		}
		return this;
	}

	public function toString() : String {
		return Type.getClassName(Type.getClass(this));
	}

	#if neko
	static function __init__() untyped {
		Output.prototype.bigEndian = false;
	}
	#end
}
