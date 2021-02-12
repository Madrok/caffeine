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

package chx.net;

import chx.lang.BlockedException;
import chx.lang.EofException;
import chx.lang.IOException;
import chx.lang.OutsideBoundsException;
import chx.net.Host;
// import haxe.io.Eof;
// import haxe.io.Error;
#if !js
typedef TcpSocket = sys.net.Socket;

// class TcpSocket extends sys.net.Socket implements chx.net.Socket {
// 	public override function read() {
// 		try {
// 			return super.read();
// 		}
// 		catch(e:Error) {
// 			switch(e) {
// 				case Blocked:
// 					return throw new BlockedException();
// 				case OutsideBounds:
// 					return throw new OutsideBoundsException();
// 				default:
// 					return throw new IOException(Std.string(e));
// 			}
// 		}
// 		catch(e:Eof) {
// 			throw new EofException();
// 		}
// 	}
// 	public override function connect(host : Host, port : Int) : Void {
// 		try {
// 			super.connect(host, port);
// 		}
// 		catch(e) {
// 			throw new IOException("Failed to connect on " + host.toString() + ":" + port);
// 		}
// 	}
// 	public override function listen(connections : Int) {
// 		try {
// 			super.listen(connections);
// 		}
// 		catch(e) {
// 			throw new IOException("listen() failure");
// 		}
// 	}
// 	public override function shutdown(read : Bool, write : Bool) : Void {
// 		try {
// 			super.shutdown(read, write);
// 		}
// 		catch(e) {
// 			throw new IOException("shutdown() failure");
// 		}
// 	}
// 	public override function bind(host : Host, port : Int) : Void {
// 		try {
// 			super.bind(host, port);
// 		}
// 		catch(e) {
// 			throw new IOException("Cannot bind socket on " + host + ":" + port);
// 		}
// 	}
// 	public override function accept() {
// 		try {
// 			var s = super.accept();
// 			return s;
// 		}
// 		catch(e) {
// 			throw new IOException(Std.string(e));
// 		}
// 	}
// 	public override function setTimeout(timeout : Float) : Void {
// 		try {
// 			super.setTimeout(timeout);
// 		}
// 		catch(e) {
// 			throw new IOException("setTimeout() failure");
// 		}
// 	}
// 	public override function waitForRead() : Void {
// 		try {
// 			super.waitForRead();
// 		}
// 		catch(e:Eof) {
// 			throw new EofException();
// 		}
// 		catch(e) {
// 			throw new IOException(Std.string(e));
// 		}
// 	}
// 	public override function setBlocking(b : Bool) : Void {
// 		try {
// 			super.setBlocking(b);
// 		}
// 		catch(e) {
// 			throw new IOException("setBlocking() failure");
// 		}
// 	}
// 	public override function setFastSend(b : Bool) : Void {
// 		try {
// 			super.setFastSend(b);
// 		}
// 		catch(e) {
// 			throw new IOException("setFastSend() failure");
// 		}
// 	}
// 	public static function select(read : Array<TcpSocket>, write : Array<TcpSocket>,
// 			others : Array<TcpSocket>, ?timeout : Float) : {
// 		read : Array<chx.net.Socket>,
// 		write : Array<chx.net.Socket>,
// 		others : Array<chx.net.Socket>
// 	} {
// 		try {
// 			return cast sys.net.Socket.select(cast read, cast write, cast others, timeout);
// 		}
// 		catch(e:Eof) {
// 			throw new EofException();
// 		}
// 		catch(e) {
// 			throw new IOException(Std.string(e));
// 		}
// 	}
// }
#else
///////////////////////////////////////////////////
////////// Javascript implementation //////////////
///////////////////////////////////////////////////
import js.node.net.Server.ServerEvent;
import sys.NodeSync;

class JsTcpSocketInput extends chx.io.Input {
	var s : TcpSocket;

	public function new(s : TcpSocket) {
		this.s = s;
	}

	override function readByte() : Int {
		s.waitInputData();
		if(s.inputData.length == 0)
			throw new BlockedException();
		var buf = s.inputData[0];
		var b = buf[s.inputPos++];
		if(s.inputPos == buf.length) {
			s.inputPos = 0;
			s.inputData.shift();
		}
		return b;
	}

	override function readBytes(buf : haxe.io.Bytes, pos : Int, len : Int) : Int {
		s.waitInputData();
		if(s.inputData.length == 0)
			throw new BlockedException();
		var nbuf = js.node.Buffer.hxFromBytes(buf);
		var startPos = pos;
		while(len > 0) {
			var buf = s.inputData[0];
			if(buf == null)
				break;
			var avail = buf.length - s.inputPos;
			if(avail > len) {
				buf.copy(nbuf, pos, s.inputPos, s.inputPos + len);
				pos += len;
				s.inputPos += len;
				break;
			}
			buf.copy(nbuf, pos, s.inputPos, s.inputPos + avail);
			pos += avail;
			len -= avail;
			s.inputData.shift();
			s.inputPos = 0;
		}
		return pos - startPos;
	}

	override function get_bytesAvailable() {
		var t = 0;
		for (b in s.inputData)
			t += b.length;
		t -= s.inputPos;
		return t;
	}
}

class JsTcpSocketOutput extends chx.io.Output {
	var s : TcpSocket;

	public function new(s : TcpSocket) {
		this.s = s;
	}

	public override function writeByte(c : Int) : Void {
		s.waitOutputData();

		if(!s.blocking && s.outputBlocked)
			throw new BlockedException();
		var buf = haxe.io.Bytes.alloc(1);
		buf.set(0, c);

		s.outputBlocked = !s.client.write(js.node.Buffer.hxFromBytes(buf));
	}
}

@:jsRequire("net", "Server")
@:allow(chx.net.JsTcpSocketInput)
@:allow(chx.net.JsTcpSocketOutput)
class TcpSocket implements chx.net.Socket {
	public static function select(read : Array<Socket>, write : Array<Socket>,
			others : Array<Socket>, ?timeout : Float) : {
		read : Array<chx.net.Socket>,
		write : Array<chx.net.Socket>,
		others : Array<chx.net.Socket>
	} {
		var resRead = [];
		var resWrite = [];
		for (sock in read) {
			var s : TcpSocket = cast sock;
			if(s.server != null) {
				// server sockets show up in 'read' if they have pending connections
				if(s.acceptQueue.length > 0)
					resRead.push(sock);
			}
			else if(s.client != null) {
				if(!s.inputBlocked && s.inputData.length > 0)
					resRead.push(sock);
			}
			else {
				// no server, no client, it's closed
				// add it to the read to get the EOF
				resRead.push(sock);
			}
		}

		for (sock in write) {
			var s : TcpSocket = cast sock;
			if(s.server != null) {
				throw new chx.lang.NullPointerException("can not write to server socket");
			}
			if(!s.outputBlocked) {
				resWrite.push(sock);
			}
		}

		return {
			read : resRead,
			write : resWrite,
			others : []
		}
	}

	public var custom : Dynamic;
	public var inputBlocked(get, null) : Bool;
	public var outputBlocked(default, null) : Bool;

	/**
	 * If this socket is a client connection, this will be set
	 */
	var client : js.node.net.Socket;

	/**
	 * If this socket is bound, the server var will be set
	 */
	var server : js.node.net.Server;

	/**
	 * Array of byte buffers of finput coming in to the socket. Accessed from JsTcpSocketInput class
	 */
	var inputData : Array<js.node.Buffer> = [];

	/**
	 * The position in the current inputData buffer for reading. Accessed from JsTcpSocketInput class
	 */
	var inputPos : Int = 0;

	var outputData : Array<js.node.Buffer> = [];
	var outputPos : Int = 0;

	var blocking : Bool = true;

	public var input(default, null) : chx.io.Input;
	public var output(default, null) : chx.io.Output;

	public function new() {
		input = new JsTcpSocketInput(this);
		output = new JsTcpSocketOutput(this);
		// will unblock on a connect()
		// server socket output is always blocked
		outputBlocked = true;
	}

	function get_inputBlocked() {
		return inputData.length == 0;
	}

	public function connect(host : Host, port : Int) {
		client = new js.node.net.Socket();
		client.on("data", (buf : js.node.Buffer)->inputData.push(buf));
		client.on("drain", () -> outputBlocked = false);
		NodeSync.callVoid(function(callb)
			client.connect(port, host.host, function() {
				outputBlocked = false;
				callb();
			}));
		// NodeSync.callVoid(function(callb)
		// 	client.connect(port, host.host, callb);
	}

	/**
	 * Called from the JsTcpSocketInput class
	 * during read operations.
	 */
	function waitInputData() {
		if(blocking)
			waitForRead();
	}

	public function waitForRead() {
		// this blocks regardless of the blocking property
		if(inputData.length == 0)
			NodeSync.wait(function()
				return inputData.length > 0);
	}

	function waitOutputData() {
		if(blocking && outputBlocked)
			NodeSync.wait(function()
				return !outputBlocked);
	}

	public function close() {
		if(client != null) {
			client.destroy();
			client = null;
			input = null;
			output = null;
		}
		if(server != null) {
			server.close();
			server = null;
			input = null;
			output = null;
		}
	}

	public function host() {
		var c = (client == null) ? server : client;
		if(server == null && client == null)
			throw new chx.lang.UnsupportedException("not bound");
		var host;
		var port;
		if(server != null) {
			host = new chx.net.Host(server
				.address()
				.address
			);
			port = server
				.address()
				.port;
		}
		else {
			host = new chx.net.Host(client
				.address()
				.address
			);
			port = client
				.address()
				.port;
		}

		return {
			host : host,
			port : port
		}
	}

	public function peer() {
		var host = new chx.net.Host(client.remoteAddress);
		var port = client.remotePort;
		return {
			host : host,
			port : port
		}
	}

	public function read() : String {
		return input
			.readAll()
			.toString();
	}

	public function setBlocking(b : Bool) {
		this.blocking = b;
	}

	public function setTimeout(timeout : Float) {
		throw "not implemented";
	}

	public function shutdown(read : Bool, write : Bool) : Void {
		throw "not implemented";
	}

	public function write(content : String) : Void {
		output.writeString(content);
	}

	/////////////////////////////////////
	////////// server methods ///////////
	/////////////////////////////////////

	/**
	 * The line up of connections to be pulled from
	 * with calls to accept()
	 */
	var acceptQueue : Array<js.node.net.Socket> = [];

	var _port : Int;
	var _host : String;

	public function bind(host : Host, port : Int) {
		if(server != null)
			throw new chx.lang.IOException("already bound");
		if(client != null)
			throw new chx.lang.IOException("already bound as client");

		// server = new js.node.net.Server();
		server = ServerMaker.createServer();

		// server.on(ServerEvent.Connection, handleConnection);
		server.on(ServerEvent.Connection, function(s : js.node.net.Socket) {
			acceptQueue.push(s);
		});
		server.on(ServerEvent.Listening, function() {
			// trace("listening: " + server
			// 	.address()
			// 	.address
			// );
		});
		server.on(ServerEvent.Error, function(e) {
			trace("Error: " + Std.string(e));
		});
		server.on(ServerEvent.Close, () -> {});
		this._host = host.host;
		this._port = port;
	}

	public function listen(connections : Int) {
		var opts = {
			exclusive : true,
			port : _port,
			host : _host,
			// backlog : connections
		}
		NodeSync.callVoid((callb) -> server.listen(opts, callb));
	}

	public function accept() {
		if(acceptQueue.length == 0)
			throw new chx.lang.IOException("no sockets to accept");
		var rawSock = acceptQueue.shift();
		var s = new TcpSocket();
		s.client = rawSock;
		s.outputBlocked = false;

		s.client.on("data", (buf : js.node.Buffer)->s.inputData.push(buf));
		s.client.on("drain", () -> s.outputBlocked = false);
		s.client.on("close", () -> s.close());
		return cast s;
	}
}

class ServerMaker {
	public static function createServer() : js.node.net.Server {
		return cast untyped require('net')
			.createServer();
	}
}
#end
