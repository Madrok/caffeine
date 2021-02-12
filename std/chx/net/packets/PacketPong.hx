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

package chx.net.packets;

/**
	Pong packet
**/
class PacketPong extends Packet {
	public inline static var ID : Int = 2;

	static function __init__() {
		Packet.register(ID, PacketPong);
	}

	override public function get_id() : Int {
		return ID;
	}

	public var pingId : Int;
	public var ping_timestamp : Float;

	/** timestamp on other machine **/
	public var remote_timestamp(default, null) : Float;

	/** time at which this packet was received **/
	public var received_timestamp(default, null) : Float;

	public function new(?p : PacketPing) {
		super();
		var now = Sys.time();
		if(p != null) {
			this.pingId = p.pingId;
			this.ping_timestamp = p.timestamp;
		}
		else {
			this.pingId = 0;
			this.ping_timestamp = 0.0;
		}
		this.remote_timestamp = now;
		this.received_timestamp = now;
	}

	override function toBytes(buf : chx.io.Output) : Void {
		buf.writeInt32(this.pingId);
		buf.writeDouble(this.ping_timestamp);
		buf.writeDouble(this.remote_timestamp);
	}

	override function fromBytes(buf : chx.io.Input) : Void {
		this.received_timestamp = Sys.time();
		this.pingId = buf.readInt32();
		this.ping_timestamp = buf.readDouble();
		this.remote_timestamp = buf.readDouble();
	}

	/**
		Get time required for ping/pong
	**/
	public function roundTripTime() : Int {
		return Std.int((received_timestamp - ping_timestamp) * 1000);
	}

	/**
		One-way trip time from host to host, in milliseconds.
	**/
	public function latency() : Int {
		return Std.int(roundTripTime() / 2);
	}

	/**
		Returns the time offset in milliseconds for the remote system clock
	**/
	public function remoteTimeOffset() : Int {
		return Std.int((remote_timestamp - ping_timestamp - roundTripTime()) * 1000);
	}
}
