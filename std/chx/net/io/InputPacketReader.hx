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

package chx.net.io;

import chx.ds.Bytes;
import chx.io.BufferedInput;
import chx.io.BytesInput;
import chx.io.Input;
import chx.net.packets.Packet;

/**
 * Safely reads [chx.net.packets.Packet] directly from an Input. This class buffers
 * input data so no information is lost if messages are broken up into
 * multiple network packets.
 * If the supplied [chx.io.Input] is not buffered, it will be buffered
 * by the constructor.
 */
class InputPacketReader {
	var input : BufferedInput;
	var length : Null<Int> = null;
	var networkVersion : Null<Int> = null;
	var type : Null<Int> = null;
	var data : Bytes = null;

	public function new(inp : Input) {
		if(inp == null)
			throw new chx.lang.FatalException("input must be non-null");
		if(Std.is(inp, BufferedInput))
			this.input = cast inp;
		else
			this.input = new BufferedInput(inp);
		input.bigEndian = true;
	}

	/**
	 * Reads a packet from Bytes, returning a packet and number of bytes consumed.
	 * If there are not enough bytes in the buffer, the packet will be null with 0 bytes
	 * consumed. Will throw a chx.lang.Exception if the packet type is not registered.
	 * @return Packet
	 */
	public function read() : chx.net.packets.Packet.PacketReadResult {
		try {
			if(input.bytesAvailable == 0)
				return null;
		}
		catch(e) {}

		if(length == null) {
			length = input.readInt32();
		}
		if(networkVersion == null) {
			networkVersion = input.readUInt16();
		}
		if(type == null) {
			type = input.readByte();
		}
		var len = length - Packet.pktHeaderSize;
		if(data != null) {
			len -= data.length;
		}
		var newData = Bytes.alloc(len);
		var read = 0;
		// do I have to catch anything here?
		read = input.readBytes(newData, 0, len);

		// we have existing buffered data,
		// add the new data to it. It may
		// still not be enough data to form
		// a complete packet
		if(data != null) {
			var b2 : Bytes = Bytes.alloc(read + data.length);
			b2.blit(0, data, 0, data.length);
			b2.blit(data.length, newData, 0, read);
			data = b2;
		}

		// not enough data yet
		if(read < len) {
			return null;
		}

		var cleanup = () -> {
			// clean up the buffers
			length = null;
			networkVersion = null;
			type = null;
			data = null;
		}
		// read and create the type
		var p : Packet = Packet.createType(type);
		if(p == null) {
			cleanup();
			throw new chx.lang.Exception("Not a registered packet " + type);
		}

		// populate the type
		try {
			var i = new BytesInput(data, 0, data.length);
			i.bigEndian = true;
			p.fromBytes(i);
		}
		catch(e) {
			cleanup();
			throw new chx.lang.Exception("Error population packet " + type);
		}
		var rv = {packet : p,
			version : networkVersion,
			bytes : (length != null) ? 0 + length : 0
		};
		cleanup();
		return rv;
	}

	/**
	 * Returns the length of the next packet in the supplied buffer, or null if it can not yet be determined
	 * @return Null<Int>
	 */
	function getPacketLength() : Null<Int> {
		// if(input.bytesAvailable < 4)
		// 	return null;
		return input.readInt32();
	}
}
