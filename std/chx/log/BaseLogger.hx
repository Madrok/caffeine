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

package chx.log;

import chx.log.LogLevel;
import haxe.PosInfos;

class BaseLogger implements IEventLog {
	public var format : LogFormat;
	public var serviceName : String;
	public var level : LogLevel;

	/**
	 * Create a logger under the program name **service**, which
	 * will only log events that are greater than or equal to
	 * LogLevel **level**
	 * @param service String to be added to log info
	 * @param level minimum level to log
	 */
	public function new(service : String, level : LogLevel) {
		if(EventLog.defaultServiceName == null)
			EventLog.defaultServiceName = service;
		if(EventLog.defaultLevel == null)
			EventLog.defaultLevel = LogLevel.INFO;
		this.serviceName = service;
		this.level = level;
		this.format = new LogFormat(LogFormat.formatLong);
	}

	/**
	 * Adds this logger to the chain of event loggers, only if it does not
	 * yet exist.
	 */
	public function addToLogChain() : Void {
		EventLog.add(this);
	}

	/**
	 * Closes this logger
	 */
	public function close() : Void {}

	public inline function debug(s : String, ?pos : PosInfos) : Void {
		log(s, DEBUG, pos);
	}

	public inline function info(s : String, ?pos : PosInfos) : Void {
		log(s, INFO, pos);
	}

	public inline function notice(s : String, ?pos : PosInfos) : Void {
		log(s, NOTICE, pos);
	}

	public inline function warn(s : String, ?pos : PosInfos) : Void {
		log(s, WARN, pos);
	}

	public inline function error(s : String, ?pos : PosInfos) : Void {
		log(s, ERROR, pos);
	}

	public inline function critical(s : String, ?pos : PosInfos) : Void {
		log(s, CRITICAL, pos);
	}

	public inline function alert(s : String, ?pos : PosInfos) : Void {
		log(s, ALERT, pos);
	}

	public inline function emerg(s : String, ?pos : PosInfos) : Void {
		log(s, EMERG, pos);
	}

	public function log(s : String, ?lvl : LogLevel, ?pos : PosInfos) : Void {
		throw "Override";
	}
}
