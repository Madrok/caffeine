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

import chx.ds.IntMap;
import chx.io.Bytes;
import chx.io.BytesInput;
import chx.io.BytesOutput;
import chx.lang.FatalException;

typedef PacketReadResult = {
	/**
	 * The packet or null if one is not ready
	 */
	var packet : Packet;

	/**
	 * The network version of the packet
	 */
	var version : Null<Int>;

	/**
	 * Number of bytes read from the stream
	 */
	var bytes : Int;
}

/**
 * A class to simplify writing network protocols. Extend with subclasses which each
 * have a unique id (0 and 0x3A-0x3F are reserved) which call Packet.register in the
 * static __init__. Then override toBytes and fromBytes with matching BytesOutput and
 * BytesInput writing and reading of the class data.
 *
 * The packet structure is
 * ```
 * 32 bits : total packet length
 * 16 bits : network version
 * 8  bits : packet id
 *  // Wraps data with a length (4 bytes)
 *	packet.writeInt32(data.length + pktHeaderSize);
 *	// add the version of the packet (2 bytes)
 *	packet.writeUInt16(networkVersion);
 *	// write the id (1 byte)
 *	packet.writeByte(get_id());
 * ```
 *
 * Changes to this structure should also be added to [chx.net.io.InputPacketReader]
 */
@:allow(chx.net.io.InputPacketReader)
class Packet {
	/**
	 * The size of the packet header before any data
	 */
	public inline static var pktHeaderSize : Int = 7;

	/**
	 * This version is a 16 bit unsigned integer that is added to the
	 * header of every network packet.
	 */
	public static var networkVersion : Int = 0;

	static var pktRegister : IntMap<Class<Packet>>;

	/**
		Every class that extends Packet must register the packet identifying byte with it's class. Packet
		ID's under 20 should be considered as reserved for standard packets.
	**/
	public static function register(id : Int, c : Class<Packet>) {
		if(pktRegister == null) {
			pktRegister = new IntMap<Class<Packet>>();
		}
		if(id < 0 || id > 255)
			throw new chx.lang.OutsideBoundsException("Packet id out of range");

		if(id == 0 && Type.getClassName(c) != "chx.net.packets.PacketNull")
			throw new FatalException("Packet id 0x00 is reserved for chx.net.packets.PacketNull");
		if(id == 1 && Type.getClassName(c) != "chx.net.packets.PacketPing")
			throw new FatalException("Packet id 1 is reserved for chx.net.packets.PacketPing");
		if(id == 2 && Type.getClassName(c) != "chx.net.packets.PacketPong")
			throw new FatalException("Packet id 2 is reserved for chx.net.packets.PacketPong");
		if(id == 3 && Type.getClassName(c) != "chx.net.packets.PacketCall")
			throw new FatalException("Packet id 3 is reserved for chx.net.packets.PacketCall");
		if(id == 4 && Type.getClassName(c) != "chx.net.packets.PacketSerialized")
			throw new FatalException("Packet id 4 is reserved for chx.net.packets.PacketSerialized");
		if(id == 5 && Type.getClassName(c) != "chx.net.packets.PacketXmlData")
			throw new FatalException("Packet id 5 is reserved for chx.net.packets.PacketXmlData");
		if(id == 6 && Type.getClassName(c) != "chx.net.packets.PacketJsonData")
			throw new FatalException("Packet id 6 is reserved for chx.net.packets.PacketJsonData");

		if(pktRegister.exists(id))
			throw new FatalException("Packet id " + id + " already registered");
		for (i in pktRegister)
			if(Type.getClassName(i) == Type.getClassName(c))
				throw new FatalException("Packet of type " + Type.getClassName(c)
					+ " already registered");
		pktRegister.set(id, c);
	}

	public var id(get, null) : Int;

	public function new() {
		this.id = get_id();
	}

	/**
		Called after a packet is created by createType() during packet reads.
		Incoming packets are created with Type.createEmptyInstance(), so any
		construction should be done here.
	**/
	public function onConstructed() {
		this.id = get_id();
	}

	/**
		Writes the packet to Bytes.
	**/
	public function write() : Bytes {
		var bb = newOutputBuffer();
		toBytes(bb);
		var data = bb.getBytes();

		var packet = newOutputBuffer();

		// if this code for writing the header is changed,
		// make sure to recount the bytes and upate the
		// inline static pktHeaderSize

		// Wraps data with a length (4 bytes)
		packet.writeInt32(data.length + pktHeaderSize);
		// add the version of the packet (2 bytes)
		packet.writeUInt16(networkVersion);
		// write the id (1 byte)
		packet.writeByte(get_id());

		// write the actual data
		packet.writeBytes(data, 0, data.length);

		return packet.getBytes();
	}

	/**
		Reads a packet from Bytes, returning a packet, the network version, and number of bytes consumed.
		If there are not enough bytes in the buffer, the packet will be null with 0 bytes consumed.
		It is up to the consumer to determine what to do if the packet network version
		does not match.
		<br />
		<h1>Throws</h1><br />
		chx.lang.Exception - Packet type is not registered.
		chx.lang.OutsideBoundsException - Buffer not big enough
	**/
	public static function read(buf : Bytes, ?pos : Int, ?len : Int) : PacketReadResult {
		if(pos == null)
			pos = 0;
		if(len == null)
			len = buf.length - pos;
		if(pos + len > buf.length)
			throw new chx.lang.OutsideBoundsException();
		var msgLen = getPacketLength(buf, pos, len);
		if(msgLen == null || len < msgLen)
			return {packet : null, version : 0, bytes : 0}
		pos += 4;

		// read the networkVersion (2 bytes)
		var bi = newInputBuffer(buf, pos, 2);
		var nv = bi.readUInt16();
		pos += 2;

		// read and create the type
		var p = createType(buf.get(pos));
		if(p == null)
			throw new chx.lang.Exception("Not a registered packet " + buf.get(pos));
		pos += 1;

		// populate the type
		bi = newInputBuffer(buf, pos);
		p.fromBytes(bi);
		return {packet : p, version : nv, bytes : msgLen};
	}

	/**
		Creates a new BytesOutput buffer with the correct endianness.
	**/
	static function newOutputBuffer() : BytesOutput {
		var b = new BytesOutput();
		b.bigEndian = true;
		return b;
	}

	/**
		Creates a new BytesInput with the correct endianness
	**/
	static function newInputBuffer(buf : Bytes, ?pos : Int, ?len : Int) : BytesInput {
		var i = new BytesInput(buf, pos, len);
		i.bigEndian = true;
		return i;
	}

	/**
		Returns the id of a packet
	**/
	function get_id() : Int {
		throw new FatalException("override");
		return 0;
	}

	/**
		Packets must override this to write all data to the data
	**/
	function toBytes(buf : chx.io.Output) : Void {
		throw new FatalException("override");
	}

	/**
		Read object in from specified Input, returning number of
		bytes consumed. The supplied Input must be in bigEndian format, by setting buf.bigEndian to true
	**/
	function fromBytes(buf : chx.io.Input) : Void {
		throw new FatalException("override");
	}

	public function toString() {
		var s = Type.getClassName(Type.getClass(this)) + ":";
		for (f in Reflect.fields(this)) {
			s += " " + f + "=" + Std.string(Reflect.field(this, f));
		}
		return s;
	}

	/**
		Creates a new packet from the byte id
	**/
	public static function createType(b : Int) : Packet {
		if(!pktRegister.exists(b))
			return null;
		var pkt = Type.createEmptyInstance(pktRegister.get(b));
		if(pkt != null)
			pkt.onConstructed();
		return pkt;
	}

	/**
		Returns the length of the next packet in the supplied buffer,
		or null if it can not yet be determined. This just returns the
		number of bytes needed to consider the buffer a complete packet.
	**/
	public static function getPacketLength(buf : Bytes, pos : Int, len : Int) : Null<Int> {
		var datalen = len - pos;
		// 4 bytes for total length of packet
		if(buf.length < 4 || datalen < 4)
			return null;

		var bi = newInputBuffer(buf, pos, 4);
		return bi.readInt32();
	}
}
