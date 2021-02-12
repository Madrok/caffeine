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

package chx.io;

import Sys;
import chx.io.FileInput;
import chx.lang.IOException;
import sys.io.File as SysFile;
#if js
import js.node.Fs;
#end

/**
 * @todo wrap all static methods
 */
// typedef File = sys.io.File;
class File {
	public static function stdout() : Output {
		return new OutputAdaptor(Sys.stdout());
	}

	public static function stdin() : Input {
		return new InputAdaptor(Sys.stdin());
	}

	public static function append(path : String, binary : Bool = true) : FileOutput {
		try {
			return new FileOutput(SysFile.append(path, binary));
		}
		catch(e) {
			return throw new IOException(Std.string(e));
		}
	}

	public static function copy(path : String, dstPath : String) : Void {
		try {
			SysFile.copy(path, dstPath);
		}
		catch(e) {
			return throw new IOException(Std.string(e));
		}
	}

	public static function getBytes(path : String) : Bytes {
		try {
			return SysFile.getBytes(path);
		}
		catch(e) {
			return throw new IOException(Std.string(e));
		}
	}

	public static function getContent(path : String) : String {
		try {
			return SysFile.getContent(path);
		}
		catch(e) {
			return throw new IOException(Std.string(e));
		}
	}

	public static function read(path : String, binary : Bool = true) : FileInput {
		try {
			return new FileInput(SysFile.read(path, binary));
		}
		catch(e) {
			return throw new IOException(Std.string(e));
		}
	}

	public static function saveBytes(path : String, bytes : Bytes) : Void {
		try {
			SysFile.saveBytes(path, bytes);
		}
		catch(e) {
			return throw new IOException(Std.string(e));
		}
	}

	public static function saveContent(path : String, content : String) : Void {
		try {
			SysFile.saveContent(path, content);
		}
		catch(e) {
			return throw new IOException(Std.string(e));
		}
	}

	#if js
	@:access(sys.io.FileOutput)
	static function missingUpdateInHxnodeJS(path : String, binary : Bool = true) {
		return new sys.io.FileOutput(Fs.openSync(path, AppendReadCreate));
	}
	#end

	public static function update(path : String, binary : Bool = true) : FileOutput {
		try {
			#if js
			return new FileOutput(missingUpdateInHxnodeJS(path, binary));
			#else
			return new FileOutput(SysFile.update(path, binary));
			#end
		}
		catch(e) {
			return throw new IOException(Std.string(e));
		}
	}

	public static function write(path : String, binary : Bool = true) : FileOutput {
		try {
			return new FileOutput(SysFile.write(path, binary));
		}
		catch(e) {
			return throw new IOException(Std.string(e));
		}
	}
}
