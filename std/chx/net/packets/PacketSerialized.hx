/*
 * Copyright (c) 2008-2009, The Caffeine-hx project contributors
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

import haxe.Serializer;
import haxe.Unserializer;

/**
	A packet that can contain haxe serialized data as well as an arbitrary integer flag.
**/
class PacketSerialized extends Packet {
	public inline static var VALUE : Int = 3;

	static function __init__() {
		Packet.register(VALUE, PacketSerialized);
	}

	override public function get_id() : Int {
		return VALUE;
	}

	/** An unsigned int 16 value **/
	public var flag : Int;

	/** haxe serialized data **/
	public var data : Dynamic;

	public function new(?s : String) {
		super();
		flag = 0;
		data = s;
	}

	override function toBytes(buf : chx.io.Output) : Void {
		var serialized = Serializer.run(data);
		buf.writeUInt16(this.flag);
		buf.writeUTF16String(serialized);
	}

	override function fromBytes(buf : chx.io.Input) : Void {
		this.flag = buf.readUInt16();
		var s = buf.readUTF16String();
		this.data = Unserializer.run(s);
	}

	/**
		Unserializes the data. Will throw anything haxe.Unserializer does.
	**/
	public function unserialize() : Dynamic {
		return haxe.Unserializer.run(this.data);
	}
}
