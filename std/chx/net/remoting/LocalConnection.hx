/*
 * Copyright (C)2005-2018 Haxe Foundation
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

package chx.net.remoting;

/**
	Allows communications to a different application that runs on the same client device
 */
class LocalConnection implements AsyncConnection {
	static var ID = 0;

	var __path : Array<String>;
	var __data : {
		ctx : Context,
		results : chx.ds.IntMap<{error : Dynamic->Void, result : Dynamic->Void}>,
		error : Dynamic->Void,
		target : String,
		cnx : Dynamic,
	};

	function new(data, path) {
		this.__path = path;
		this.__data = data;
	}

	public function resolve(name) : AsyncConnection {
		var s = new LocalConnection(__data, __path.copy());
		s.__path.push(name);
		return s;
	}

	public function setErrorHandler(h) {
		__data.error = h;
	}

	public function call(params : Array<Dynamic>, ?onResult : Dynamic->Void) : Void {
		try {
			var id = ID++;

			if(!__data.cnx.send(__data.target, "remotingCall", id, __path.join("."),
				haxe.Serializer.run(params)))
				throw "Remoting call failure";

			__data.results.set(id, {error : __data.error, result : onResult});
		}
		catch(e:Dynamic) {
			__data.error(e);
		}
	}

	public function close() {
		__data.cnx.close();
	}

	static function remotingCall(c : LocalConnection, id : Int, path : String, args : String) {
		var r;
		try {
			if(c.__data.ctx == null)
				throw "No context shared for this connection";
			var ret = c.__data.ctx.call(path.split("."), haxe.Unserializer.run(args));
			r = haxe.Serializer.run(ret);
		}
		catch(e:Dynamic) {
			var s = new haxe.Serializer();
			s.serializeException(e);
			r = s.toString();
		}
		// don't forward 'send' errors on connection since it's only the receiving side
		c.__data.cnx.send(c.__data.target, "remotingResult", id, r);
	}

	static function remotingResult(c : LocalConnection, id : Int, result : String) {
		var f = c.__data.results.get(id);
		if(f == null)
			c.__data.error("Invalid result ID " + id);
		c.__data.results.remove(id);
		var val : Dynamic;
		try {
			val = new haxe.Unserializer(result)
				.unserialize();
		}
		catch(e:Dynamic) {
			f.error(e);
			return;
		}
		if(f.result != null)
			f.result(val);
	}
}
