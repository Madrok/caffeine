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

package sys.net;

import chx.lang.*;
import cpp.NativeSocket;
import cpp.NativeString;
import cpp.Pointer;

private class SocketInput extends chx.io.Input {
	var __s : Dynamic;

	public function new(s : Dynamic) {
		__s = s;
	}

	public function readByte() {
		return try {
			NativeSocket.socket_recv_char(__s);
		}
		catch(e:Dynamic) {
			if(e == "Blocking")
				throw new BlockedException();
			else if(__s == null)
				throw new IOException(Std.string(e));
			else
				throw new EofException();
		}
	}

	public override function readBytes(buf : chx.ds.Bytes, pos : Int, len : Int) : Int {
		var r;
		if(__s == null)
			throw new chx.lang.Exception("Invalid handle");
		try {
			r = NativeSocket.socket_recv(__s, buf.getData(), pos, len);
		}
		catch(e:Dynamic) {
			if(e == "Blocking")
				throw new BlockedException();
			else
				throw new IOException(Std.string(e));
		}
		if(r == 0)
			throw new EofException();
		return r;
	}

	public override function close() {
		super.close();
		if(__s != null)
			NativeSocket.socket_close(__s);
	}
}

private class SocketOutput extends chx.io.Output {
	var __s : Dynamic;

	public function new(s : Dynamic) {
		__s = s;
	}

	public function writeByte(c : Int) {
		if(__s == null)
			throw new Exception("Invalid handle");
		try {
			NativeSocket.socket_send_char(__s, c);
		}
		catch(e:Dynamic) {
			if(e == "Blocking")
				throw new BlockedException();
			else
				throw new IOException(Std.string(e));
		}
	}

	public override function writeBytes(buf : chx.ds.Bytes, pos : Int, len : Int) : Int {
		return try {
			NativeSocket.socket_send(__s, buf.getData(), pos, len);
		}
		catch(e:Dynamic) {
			if(e == "Blocking")
				throw new BlockedException();
			else if(e == "EOF")
				throw new EofException();
			else
				throw new IOException(Std.string(e));
		}
	}

	public override function close() {
		super.close();
		if(__s != null)
			NativeSocket.socket_close(__s);
	}
}

@:coreApi
class Socket implements chx.net.Socket {
	private var __s : Dynamic;

	// We need to keep these values so that we can restore
	// them if we re-create the socket for ipv6 as in
	// connect() and bind() below.
	private var __timeout : Float = 0.0;
	private var __blocking : Bool = true;
	private var __fastSend : Bool = false;

	public var input(default, null) : chx.io.Input;
	public var output(default, null) : chx.io.Output;
	public var custom : Dynamic;

	public function new() : Void {
		init();
	}

	private function init() : Void {
		if(__s == null)
			__s = NativeSocket.socket_new(false);
		// Restore these values if they changed. This can happen
		// in connect() and bind() if using an ipv6 address.
		setTimeout(__timeout);
		setBlocking(__blocking);
		setFastSend(__fastSend);
		input = new SocketInput(__s);
		output = new SocketOutput(__s);
	}

	public function close() : Void {
		NativeSocket.socket_close(__s);
		untyped {
			var input : SocketInput = cast input;
			var output : SocketOutput = cast output;
			input.__s = null;
			output.__s = null;
		}
		input.close();
		output.close();
	}

	public function read() : String {
		var bytes : chx.ds.BytesData = NativeSocket.socket_read(__s);
		if(bytes == null)
			return "";
		var arr : Array<cpp.Char> = cast bytes;
		return NativeString.fromPointer(Pointer.ofArray(arr));
	}

	public function write(content : String) : Void {
		NativeSocket.socket_write(__s, chx.ds.Bytes
			.ofString(content)
			.getData()
		);
	}

	public function connect(host : Host, port : Int) : Void {
		try {
			if(host.ip == 0 && host.host != "0.0.0.0") {
				// hack, hack, hack
				var ipv6 : chx.ds.BytesData = Reflect.field(host, "ipv6");
				if(ipv6 != null) {
					close();
					__s = NativeSocket.socket_new_ip(false, true);
					init();
					NativeSocket.socket_connect_ipv6(__s, ipv6, port);
				}
				else
					throw new chx.lang.Exception("Unresolved host");
			}
			else
				NativeSocket.socket_connect(__s, host.ip, port);
		}
		catch(s:String) {
			if(s == "Invalid socket handle")
				throw new Exception(s);
			else if(s == "Blocking") {
				// Do nothing, this is not a real error, it simply indicates
				// that a non-blocking connect is in progress
			}
			else
				throw new IOException("Failed to connect on " + host.toString() + ":" + port);
		}
	}

	public function listen(connections : Int) : Void {
		NativeSocket.socket_listen(__s, connections);
	}

	public function shutdown(read : Bool, write : Bool) : Void {
		NativeSocket.socket_shutdown(__s, read, write);
	}

	public function bind(host : Host, port : Int) : Void {
		if(host.ip == 0 && host.host != "0.0.0.0") {
			var ipv6 : chx.ds.BytesData = Reflect.field(host, "ipv6");
			if(ipv6 != null) {
				close();
				__s = NativeSocket.socket_new_ip(false, true);
				init();
				NativeSocket.socket_bind_ipv6(__s, ipv6, port);
			}
			else
				throw new chx.lang.Exception("Unresolved host");
		}
		else
			NativeSocket.socket_bind(__s, host.ip, port);
	}

	public function accept() : Socket {
		var c = NativeSocket.socket_accept(__s);
		var s = Type.createEmptyInstance(Socket);
		s.__s = c;
		s.input = new SocketInput(c);
		s.output = new SocketOutput(c);
		return s;
	}

	public function peer() : {host : Host, port : Int} {
		var a : Dynamic = NativeSocket.socket_peer(__s);
		if(a == null) {
			return null;
		}
		var h = new Host("127.0.0.1");
		untyped h.ip = a[0];
		return {host : h, port : a[1]};
	}

	public function host() : {host : Host, port : Int} {
		var a : Dynamic = NativeSocket.socket_host(__s);
		if(a == null) {
			return null;
		}
		var h = new Host("127.0.0.1");
		untyped h.ip = a[0];
		return {host : h, port : a[1]};
	}

	public function setTimeout(timeout : Float) : Void {
		__timeout = timeout;
		NativeSocket.socket_set_timeout(__s, timeout);
	}

	public function waitForRead() : Void {
		select([this], null, null, null);
	}

	public function setBlocking(b : Bool) : Void {
		__blocking = b;
		NativeSocket.socket_set_blocking(__s, b);
	}

	public function setFastSend(b : Bool) : Void {
		__fastSend = b;
		NativeSocket.socket_set_fast_send(__s, b);
	}

	public static function select(read : Array<Socket>, write : Array<Socket>,
			others : Array<Socket>, ?timeout : Float) : {
		read : Array<Socket>,
		write : Array<Socket>,
		others : Array<Socket>
	} {
		var neko_array = NativeSocket.socket_select(read, write, others, timeout);
		if(neko_array == null)
			throw new IOException("Select error");
		return @:fixed {
			read:neko_array[0],
			write:neko_array[1],
			others:neko_array[2]
		};
	}
}
