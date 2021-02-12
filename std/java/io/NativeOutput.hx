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

package java.io;

import chx.io.Output;
import haxe.Int64;
import haxe.io.Bytes;
import haxe.io.Eof;
import java.io.EOFException;
import java.io.IOException;

@:native('haxe.java.io.NativeOutput') class NativeOutput extends Output {
	var stream : java.io.OutputStream;

	public function new(stream) {
		this.stream = stream;
	}

	public function writeByte(c : Int) : Void {
		try {
			stream.write(c);
		}
		catch(e:EOFException) {
			throw new chx.lang.EofException();
		}
		catch(e:IOException) {
			throw new chx.lang.IOException(e.getMessage());
		}
	}

	override public function close() : Void {
		try {
			stream.close();
		}
		catch(e:IOException) {
			throw new chx.lang.IOException(e.getMessage());
		}
	}

	override public function flush() : Void {
		try {
			stream.flush();
		}
		catch(e:IOException) {
			throw new chx.lang.IOException(e.getMessage());
		}
	}
}