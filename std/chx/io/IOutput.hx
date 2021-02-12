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

import chx.vm.Lock;

/**
	An Output is an abstract writer. A specific output implementation will only
	have to override the [writeChar] and maybe the [write], [flush] and [close]
	methods.
**/
interface IOutput {
	/** A chx.vm.Lock may be added to the Output and available for use **/
	var lock:Lock;

	/**
	 * Write a single byte (Unsigned Int 8) to the output
	 * @param c
	 * @throws chx.lang.IOException on error
	 */
	function writeByte(c:Int):Void;

	/**
	 * Write the content of a Bytes to the output stream.
	 * @param b the bytes buffer to write
	 * @throws [BlockedException] when output blocks.
	 */
	function write(b:Bytes):Void;

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
	function writeBytes(s:Bytes, pos:Int, len:Int):Int;

	/**
	 * Write `x` as 8-bit signed integer.
	 * @param x the integer to write
	 * @throws [OverflowException] if the integer is outside the range of a signed int8
	 */
	function writeInt8(x:Int):Void;

	/**
	 * Write `x` as 16-bit signed integer. Endianness is specified by the `bigEndian` property.
	 * @param x the integer to write
	 * @throws [OverflowException] if the integer is outside the range of a signed int16
	 */
	function writeInt16(x:Int):Void;

	/**
	 * Write `x` as 16-bit unsigned integer. Endianness is specified by the `bigEndian` property.
	 * @param x the integer to write
	 * @throws [OverflowException] if the integer is outside the range of an unsigned int16
	 */
	function writeUInt16(x:Int):Void;

	/**
	 * Write `x` as 24-bit signed integer. Endianness is specified by the `bigEndian` property.
	 * @param x the integer to write
	 * @throws [OverflowException] if the integer is outside the range of a signed int24
	 */
	function writeInt24(x:Int):Void;

	/**
	 * Write `x` as 24-bit unsigned integer. Endianness is specified by the `bigEndian` property.
	 * @param x the integer to write
	 * @throws [OverflowException] if the integer is outside the range of an unsigned int24
	 */
	function writeUInt24(x:Int):Void;

	/**
	 * Reads bytes directly from the specified Input until an
	 * [EofException] is encountered, writing untranslated
	 * bytes to this output.
	 * @param i An input stream
	 * @param bufsize A default buffer chunk size
	 * @throws chx.lang.BlockedException if the input blocks
	 */
	function writeInput(i:chx.io.Input, ?bufsize:Int):Void;

	/**
	 * Write a variable length encoded unsigned integer.
	 * @param value the value to encode
	 */
	function writeLeb128U(value:Int):Void;

	/**
	 * Write a variable length encoded signed integer.
	 * @param value the value to encode
	 */
	function writeLeb128(value:Int):Void;

	/**
	 * Write a LEB128 integer length, then the string. This simplifies
	 * input reading in binary streams.
	 * @param s The string to be written to the stream
	 * @return Output
	 */
	public function writeUTF16String(s:String):IOutput;

	/**
	 * Write a boolean to the stream. Represented as a 0 or 1
	 * @param v true or false
	 */
	public function writeBool(v:Bool):Void;

	/**
	 * Writes a formatted string in the printf style.
	 * @see chx.text.Sprintf
	 * @param	format printf() compatible format
	 * @param	args arguments to substitute into format
	 * @param	prependLength set to true to use writeUTF() method
	 * @return this output stream
	 */
	public function printf(format:String, args:Array<Dynamic> = null, prependLength:Bool = false):IOutput;

	public function toString():String;
}
