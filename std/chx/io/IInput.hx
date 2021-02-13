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
package chx.io;

import chx.ds.Bytes;

/**
 * An abstract reader. See chx.io for implementations
 *
 * All functions that read data throw a chx.lang.EofException
 * when and end of file is encountered.
 */
interface IInput {
	/**
	 * Returns number of bytes available to be read without blocking.
	 * May or may not be implemented by subclasses.
	 */
	var bytesAvailable(get, null) : Int;

	/**
	 * Abstract method for reading an unsigned 8 bit value from the
	 * input stream. For a signed value, use readInt8.
	 * @return Int Unsigned 8 bit value
	 */
	function readByte() : Int;

	/**
	 * Reads up to len bytes from the input buffer, returning the number of
	 * bytes that were actually available to read
	 * @param s A buffer to read from
	 * @param pos Position to start reading
	 * @param len Number of bytes to read
	 * @return Int Number of bytes read
	 * @throws [OutsideBoundsException] if the pos and len parameters don't make sense
	 */
	function readBytes(s : Bytes, pos : Int, len : Int) : Int;

	/**
	 * Returns true if the Input is at the end of file.
	**/
	public function isEof() : Bool;

	/**
	 * Read and return all available data.
	 * The `bufsize` optional argument specifies the size of chunks by
	 * which data is read. Its default value is target-specific.
	 * @param bufsize Size of chunks.
	 * @return Bytes A buffer with bytes
	 * @throws [BlockedException] if input is blocked
	 */
	function readAll(?bufsize : Int) : Bytes;

	/**
	 * Read `len` bytes and write them into `s` to the position specified by `pos`.
	 * Unlike `readBytes`, this method tries to read the exact `len` amount of bytes.
	 * @param s The buffer to read from
	 * @param pos Position to start reading at
	 * @param len number of bytes to read
	 * @throws [BlockedException] if input is blocked
	 */
	function readFullBytes(s : Bytes, pos : Int, len : Int) : Void;

	/**
	 * Reads nbytes from the input stream, by calling readBytes until nbytes is reached
	 * @param nbytes Number of bytes to read
	 * @return Bytes Buffer with read bytes
	 * @throws [BlockedException] if input is blocked
	 */
	function read(nbytes : Int) : Bytes;

	/**
	 * Reads from input until an \n or \r\n sequence is reached.
	 * @return String
	 */
	function readLine() : String;

	/**
	 * Reads a boolean from the stream. Returns true for
	 * values other than 0
	 * @return Bool true or false
	 */
	public function readBool() : Bool;

	/**
	 * Reads a 16 bit unsigned int length value, then the string.
	 *
	 * @return String encoded with length from stream
	**/
	public function readUTF16String() : String;

	/**
	 * Read a variable length encoded unsigned integer.
	 * @return Int integer value
	 */
	public function readLeb128() : Int;

	/**
	 * Read a variable length encoded signed integer.
	 */
	public function readLeb128U() : Int;
}
