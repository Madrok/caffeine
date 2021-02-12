/*
 * Copyright (c) 2008-2021, The Caffeine-hx project contributors
 * Original author : Russell Weir
 * Contributors:
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
 * THIS SOFTWARE IS PROVIDED BY THE CAFFEINE-HX PROJECT CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE CAFFEINE-HX PROJECT CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
 * THE POSSIBILITY OF SUCH DAMAGE.
 */

/*
 * Copyright (c) 2005-2008, The haXe Project Contributors
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
 * THIS SOFTWARE IS PROVIDED BY THE HAXE PROJECT CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE HAXE PROJECT CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 */
package chx.io;

import chx.lang.BlockedException;
import chx.lang.EofException;
import chx.lang.OutsideBoundsException;
import chx.lang.OverflowException;
import chx.text.Sprintf;
import chx.vm.Lock;

/**
	An Output is an abstract writer. A specific output implementation will only
	have to override the [writeChar] and maybe the [write], [flush] and [close]
	methods.
**/
class Output implements IOutput {
	/** A chx.vm.Lock may be added to the Output and available for use **/
	public var lock:Lock;

	/**
		Write a single byte (Unsigned Int 8) to the output
		@throws chx.lang.IOException on error
	**/
	public override function writeByte(c:Int):Void {
		throw new chx.lang.FatalException("Not implemented");
	}

	/**
	 * Write the content of a Bytes to the output stream.
	 * @param b the bytes buffer to write
	 * @throws [BlockedException] when output blocks.
	 */
	public override function write(b:Bytes):Void {
		var l = b.length;
		var p = 0;
		while (l > 0) {
			var k = writeBytes(b, p, l);
			if (k == 0)
				throw new BlockedException();
			p += k;
			l -= k;
		}
	}

	/**
	 * Write `len` bytes from `s` starting by position specified by `pos`.
	 * Returns the actual length of written data that can differ from `len`.
	 * See [writeFullBytes] that tries to write the exact amount of specified bytes.
	 * @param s a bytes buffer
	 * @param pos starting position to write from
	 * @param len number of bytes to write
	 * @return Int number of bytes written
	 * @throws [OutsideBoundsException] if pos and len don't make sense
	 */
	public override function writeBytes(s:Bytes, pos:Int, len:Int):Int {
		#if !neko
		if (pos < 0 || len < 0 || pos + len > s.length)
			throw new OutsideBoundsException();
		#end
		var b = #if js @:privateAccess s.b #else s.getData() #end;
		var k = len;
		while (k > 0) {
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
	 * Write `x` as 8-bit signed integer.
	 * @param x the integer to write
	 * @throws [OverflowException] if the integer is outside the range of a signed int8
	 */
	public override function writeInt8(x:Int) {
		if (x < -0x80 || x >= 0x80)
			throw new OverflowException();
		writeByte(x & 0xFF);
	}

	/**
	 * Write `x` as 16-bit signed integer. Endianness is specified by the `bigEndian` property.
	 * @param x the integer to write
	 * @throws [OverflowException] if the integer is outside the range of a signed int16
	 */
	public override function writeInt16(x:Int) {
		if (x < -0x8000 || x >= 0x8000)
			throw new OverflowException();
		writeUInt16(x & 0xFFFF);
	}

	/**
	 * Write `x` as 16-bit unsigned integer. Endianness is specified by the `bigEndian` property.
	 * @param x the integer to write
	 * @throws [OverflowException] if the integer is outside the range of an unsigned int16
	 */
	public override function writeUInt16(x:Int) {
		if (x < 0 || x >= 0x10000)
			throw new OverflowException();
		if (bigEndian) {
			writeByte(x >> 8);
			writeByte(x & 0xFF);
		} else {
			writeByte(x & 0xFF);
			writeByte(x >> 8);
		}
	}

	/**
	 * Write `x` as 24-bit signed integer. Endianness is specified by the `bigEndian` property.
	 * @param x the integer to write
	 * @throws [OverflowException] if the integer is outside the range of a signed int24
	 */
	public override function writeInt24(x:Int) {
		if (x < -0x800000 || x >= 0x800000)
			throw new OverflowException();
		writeUInt24(x & 0xFFFFFF);
	}

	/**
	 * Write `x` as 24-bit unsigned integer. Endianness is specified by the `bigEndian` property.
	 * @param x the integer to write
	 * @throws [OverflowException] if the integer is outside the range of an unsigned int24
	 */
	public override function writeUInt24(x:Int) {
		if (x < 0 || x >= 0x1000000)
			throw new OverflowException();
		if (bigEndian) {
			writeByte(x >> 16);
			writeByte((x >> 8) & 0xFF);
			writeByte(x & 0xFF);
		} else {
			writeByte(x & 0xFF);
			writeByte((x >> 8) & 0xFF);
			writeByte(x >> 16);
		}
	}

	/**
	 * Reads bytes directly from the specified Input until an
	 * [EofException] is encountered, writing untranslated
	 * bytes to this output.
	 * @param i An input stream
	 * @param bufsize A default buffer chunk size
	 * @throws chx.lang.BlockedException if the input blocks
	 */
	public override function writeInput(i:chx.io.Input, ?bufsize:Int):Void {
		if (bufsize == null)
			bufsize = 4096;
		var buf = Bytes.alloc(bufsize);
		try {
			while (true) {
				var len = i.readBytes(buf, 0, bufsize);
				if (len == 0)
					throw new BlockedException();
				var p = 0;
				while (len > 0) {
					var k = writeBytes(buf, p, len);
					if (k == 0)
						throw new BlockedException();
					p += k;
					len -= k;
				}
			}
		} catch (e:EofException) {}
	}

	/**
	 * Write a variable length encoded unsigned integer.
	 * @param value the value to encode
	 */
	public function writeLeb128U(value:Int) {
		var byte = 0;

		do {
			byte = value & 0x7F;
			value >>= 7;
			if (value != 0)
				byte |= 0x80;

			writeByte(byte);
		} while (value != 0);
	}

	/**
	 * Write a variable length encoded signed integer.
	 * @param value the value to encode
	 */
	public function writeLeb128(value:Int) {
		var byte = 0;

		while (true) {
			byte = value & 0x7F;
			value >>= 7;

			if ((value == 0 && byte & 0x40 == 0) || (value == -1 && byte & 0x40 != 0)) {
				writeByte(byte);
				break;
			} else {
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
	public function writeUTF16String(s:String):Output {
		var b = Bytes.ofString(s);
		writeLeb128U(b.length);
		writeFullBytes(b, 0, b.length);
		return this;
	}

	/**
	 * Write a boolean to the stream. Represented as a 0 or 1
	 * @param v true or false
	 */
	public function writeBool(v:Bool):Void {
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
	public function printf(format:String, args:Array<Dynamic> = null, prependLength:Bool = false):Output {
		var s = Sprintf.format(format, args);
		if (prependLength) {
			writeUTF16String(s);
		} else {
			writeString(s);
		}
		return this;
	}

	public function toString():String {
		return Type.getClassName(Type.getClass(this));
	}
}
