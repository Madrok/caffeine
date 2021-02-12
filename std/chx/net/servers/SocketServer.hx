/*
 * Copyright (c) 2008-2021, Russell Weir, The haXe Project Contributors
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification, are permitted
 * provided that the following conditions are met:
 *
 * - Redistributions of source code must retain the above copyright notice, this list of conditions
 *  and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright notice, this list of conditions
 *  and the following disclaimer in the documentation and/or other materials provided with the distribution.
 * - Neither the name of the author nor the names of its contributors may be used to endorse or promote
 *  products derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

package chx.net.servers;

import chx.lang.EofException;
import chx.net.Host;
import chx.net.Socket;
import haxe.CallStack;
import haxe.Exception;
import haxe.Timer;
import haxe.io.Bytes;

interface ServerClientList<ClientData> {
	var clients : List<ClientData>;
}

private typedef CustomData<SockType:Socket, ClientData> = {
	var buffer : Bytes;
	var bufbytes : Int;
	var clientData : ClientData;
}

/**
 * A basic socket server. To implement, subclass this, override all the "on" methods,
 * then either call poll() from your main loop, or use the function run() if running
 * in a separate thread for example.
 */
class SocketServer<SockType:Socket, ClientData> implements ServerClientList<ClientData> {
	/**
		Each client has an associated buffer. This is the initial buffer size which
		is set to 128 bytes by default.
	**/
	public static var DEFAULT_BUFSIZE = 256;

	/**
		Each client has an associated buffer. This is the maximum buffer size which
		is set to 64K by default. When that size is reached and some data can't be processed,
		the client is disconnected.
	**/
	public static var MAX_BUFSIZE = (1 << 16);

	/**
		Each client has an output buffer, for buffering file output. This is 4K by default.
	**/
	public static var MAX_OUTBUFSIZE = (1 << 12);

	/**
		This is the value of number client requests that the server socket
		listen for. By default this number is 10 but can be increased for
		servers supporting a large number of simultaneous requests.
	**/
	public var listenCount : Int;

	/**
		Interval in seconds the poll() function will wait in a Select() call.
		Defaults to 0.
	**/
	public var pollTimeout : Float;

	public var clients : List<ClientData>;

	var rsocks : Array<SockType>; // reading sockets
	var wsocks : Array<SockType>; // writing sockets

	var server : SockType;
	var fSelect : SelectFunction;
	var _timer : haxe.Timer;

	/**
	 * Create a server instance. When subclassing this server,
	 * you would need to call super(new Socket(), Socket.select); in
	 * your constructor.
	 * @param socket A new socket of type T
	 * @param selectStaticMethod The select() static method for socket type T
	 */
	private function new(socket : SockType /*, selectStaticMethod : SelectFunction<SockType>*/) {
		clients = new List();
		rsocks = new Array();
		wsocks = new Array();
		listenCount = 10;
		pollTimeout = 0;
		this.server = socket;
		this.fSelect = Reflect.field(Type.getClass(socket), "select");
		if(this.fSelect == null)
			throw new chx.lang.FatalException("no static select() method on socket");
	}

	/**
	 * Bind the server to an ip or localhost on the specified port.
	 * @param host Usually localhost or server ip address
	 * @param port port to bind to
	 */
	public function bind(host : Host, port : Int) {
		if(server == null)
			throw new Exception("socket null");
		if(fSelect == null)
			throw new Exception("selectStaticMethod is null");
		server.bind(host, port);
		server.listen(listenCount);
		rsocks = [server];
	}

	/**
	 * Shutdown the server.
	 */
	public function stop() {
		if(_timer != null)
			_timer.stop();
		_timer = null;
		for (i in 1...rsocks.length) {
			try {
				rsocks[i].close();
			}
			catch(e) {}
		}
		try {
			server.close();
		}
		catch(e) {}

		fSelect = null;
		clients = new List();
		rsocks = [];
		wsocks = [];
		server.close();
		server = null;
		onShutdown();
	}

	/**
	 * Use this function to run the server in a thread, or see [poll] for
	 * main loop use.
	 */
	public function run() {
		// while(true && server != null && poll()) {}
		// stop();
		if(_timer != null)
			throw new chx.lang.UnsupportedException("called run() method on running server");
		_timer = new Timer(10);
		_timer.run = () -> poll();
	}

	/**
	 * Closes the client connection and removes it from the client List.
	 * @param s client socket
	 * @return Bool true if socket was active and removed.
	 */
	public function closeConnection(sock : SockType) : Bool {
		var data : CustomData<Socket, ClientData> = sock.custom;
		try
			sock.close()
		catch(e) {};
		rsocks.remove(sock);
		wsocks.remove(sock);
		if(data == null || !clients.remove(data.clientData))
			return false;

		onDisconnect(data.clientData);
		return true;
	}

	private function isset(s : SockType, sa : Array<SockType>) {
		for (i in sa) {
			if(i == s)
				return true;
		}
		return false;
	}

	public function addWriteSock(s : SockType) : Bool {
		if(!isset(s, wsocks)) {
			wsocks.push(s);
			return true;
		}
		return false;
	}

	public function removeWriteSock(s : SockType) : Void {
		wsocks.remove(s);
	}

	/**
	 * This method can be used instead of writing directly to the socket.
	 * It ensures that all the data is correctly sent. If an error occurs
	 * while sending the data, no exception will occur but the client will
	 * be gracefully disconnected.
	 * @param s client socket
	 * @param buf buffer to send
	 * @param pos position in buffer to start
	 * @param len number of bytes to write
	 */
	public function clientWrite(sock : SockType, buf : Bytes, pos : Int, len : Int) {
		try {
			while(len > 0) {
				var nbytes = sock.output.writeBytes(buf, pos, len);
				pos += nbytes;
				len -= nbytes;
			}
		}
		catch(e) {
			trace(e);
			closeConnection(sock);
		}
	}

	function readData(sock : SockType) {
		if(sock.input == null)
			throw new chx.lang.EofException();
		var data : CustomData<SockType, ClientData> = sock.custom;
		var buflen = data.buffer.length;
		// eventually double the buffer size
		if(data.bufbytes == buflen) {
			var nsize = buflen * 2;
			if(nsize > MAX_BUFSIZE) {
				if(buflen == MAX_BUFSIZE)
					throw new Exception("Max socket client buffer size reached");
				nsize = MAX_BUFSIZE;
			}
			var buf2 = Bytes.alloc(nsize);
			buf2.blit(0, sock.custom.buffer, 0, buflen);
			buflen = nsize;
			sock.custom.buffer = buf2;
		}
		// read the available data
		var nbytes = sock.input.readBytes(data.buffer, data.bufbytes, buflen - data.bufbytes);
		data.bufbytes += nbytes;
	}

	function processData(sock : SockType) {
		var data : CustomData<SockType, ClientData> = sock.custom;
		var pos = 0;
		while(data.bufbytes > 0) {
			var nbytes = onReadable(data.clientData, data.buffer, pos, data.bufbytes);
			if(nbytes == 0)
				break;
			pos += nbytes;
			data.bufbytes -= nbytes;
		}
		if(pos > 0)
			data.buffer.blit(0, data.buffer, pos, data.bufbytes);
	}

	/**
	 * Polls the server. This is what checks all the sockets by
	 * calling select() on the server socket. Functions like
	 * [onConnect] and [onReadable] are called from here as new data
	 * becomes available.
	 * @return false when socket is closed
	 */
	public function poll() {
		if(fSelect == null)
			return false;
		var actsock = fSelect(cast rsocks, cast wsocks, null, pollTimeout);
		for (sock in actsock.write) {
			var data : CustomData<SockType, ClientData> = sock.custom;

			if(data == null) {
				throw new Exception("Uninitialized client");
			}
			// read & process the data
			try {
				onWritable(data.clientData);
			}
			catch(e:haxe.io.Eof) {
				trace(e);
				closeConnection(cast sock);
			}
			catch(e:EofException) {
				trace(e);
				closeConnection(cast sock);
			}
			catch(e) {
				onError(e);
			}
		}
		for (sock in actsock.read) {
			var data : CustomData<SockType, ClientData> = sock.custom;

			if(data == null) {
				// no associated client : it's our server socket
				// accepting a connection
				var sock : SockType = cast server.accept();
				sock.setBlocking(false);
				data = {
					clientData : null,
					buffer : Bytes.alloc(DEFAULT_BUFSIZE),
					bufbytes : 0,
				};
				// bind the client
				sock.custom = data;
				// create the ClientData
				try {
					data.clientData = onConnect(sock);
				}
				catch(e) {
					onError(e);
					try
						sock.close()
					catch(e) {};
					continue;
				}
				// adds the client to the lists
				rsocks.push(sock);
				clients.add(data.clientData);
				continue;
			}
			else {
				// read & process the data
				try {
					readData(cast sock);
					processData(cast sock);
				}
				catch(e:EofException) {
					if(!closeConnection(cast sock))
						throw new Exception("Error - closing socket");
				}
				catch(e:Exception) {
					trace(e);
					onInternalError(data.clientData, e);
					if(!closeConnection(cast sock))
						throw new Exception("Error - closing socket");
				}
			}
		}
		return true;
	}

	/**
	 * The [onConnect] method should return a new instance of the
	 * [ClientData] class to attach to each new connection. It is
	 * a good idea to store things like the actual socket, or
	 * the socket i/o methods in the CLientData structure, as this
	 * is what is passed back in the other on* callback methods.
	 * @param s the new client socket
	 * @return ClientData
	 */
	public function onConnect(s : SockType) : ClientData {
		throw new Exception("onConnect not implemented");
	}

	/**
	 * This method is called after a client has been disconnected.
	 * @param d
	 */
	public function onDisconnect(d : ClientData) {}

	/**
	 * This method is called when some data has been read into a Client buffer.
	 * If the data can be handled, then you can return the number of bytes handled
	 * that needs to be removed from the buffer. It the data can't be handled (some
	 * part of the message is missing for example), return 0. Data is buffered up to
	 * [MAX_BUFSIZE] bytes.
	 *
	 * @param d your ClientData type
	 * @param buf buffer containing input from client
	 * @param bufpos position in buffer for valid data
	 * @param buflen number of bytes available to be read
	 */
	public function onReadable(d : ClientData, buf : Bytes, bufpos : Int, buflen : Int) : Int {
		throw new Exception("onReadable not implemented");
		return 0;
	}

	/**
	 * This method is called when a socket can be written to.
	 * @param d your ClientData type
	 */
	public function onWritable(d : ClientData) {
		return 0;
	}

	/**
	 * Called when an error occured. This enable you to log the error somewhere.
	 * By default the error is displayed using [trace].
	 * @param e
	 */
	public function onError(e : Dynamic) {
		#if( haxe_ver >= 4.1 )
		if(Std.is(e, Exception)) {
			trace(e);
			trace(e.message);
			trace(e.stack);
		}
		else {
			trace(Std.string(e) + "\n" + CallStack.toString(e));
		}
		#else
		trace(Std.string(e) + "\n" + haxe.Stack.toString(haxe.Stack.exceptionStack()));
		#end
	}

	/**
	 * Called when an error that should generate a 500 response occurs.
	 * By default the error is displayed using [trace].
	 * @param d
	 * @param e
	 */
	public function onInternalError(d : ClientData, e : Dynamic) {
		trace("SocketServer::internal error");
		onError(e);
	}

	/**
	 * Called when server has stopped and all clients have been disconnected
	 */
	public function onShutdown() : Void {}
}
