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
	Simple RPC
**/
class PacketCall extends chx.net.packets.Packet {
	public inline static var ID : Int = 3;

	static function __init__() {
		Packet.register(ID, PacketCall);
	}

	override function get_id() {
		return ID;
	}

	/** Request id **/
	public var reqId : Int;

	/** Function path **/
	public var path : Array<String>;

	/** Function call arguments **/
	public var params : Array<Dynamic>;

	override function toBytes(buf : chx.io.Output) : Void {
		buf.writeInt32(reqId);
		buf.writeUTF16String(path.join("."));
		buf.writeUTF16String(haxe.Serializer.run(params));
	}

	override function fromBytes(buf : chx.io.Input) : Void {
		reqId = buf.readInt32();
		path = buf
			.readUTF16String()
			.split(".");
		params = haxe.Unserializer.run(buf.readUTF16String());
	}
}
