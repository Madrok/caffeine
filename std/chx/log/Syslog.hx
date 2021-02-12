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

import chx.io.StringOutput;
import haxe.PosInfos;

#if( sys )
/**
 * In a Syslog, the serviceName is already used by default, so
 * if the default log format is being used, it will be replaced
 * with new LogFormat("%d : %i (%C:%m:%l)");
 */
class Syslog extends BaseLogger implements IEventLog {
	/** the system command needed to add entries to the syslog service **/
	public static var loggerCmd : String = "logger";

	/** the default format for Syslog type loggers */
	public static var defaultFormat : LogFormat = new LogFormat(LogFormat.formatSyslog);

	public function new(service : String, ?level : LogLevel) {
		super(service, level);
		this.format = defaultFormat.clone();
	}

	override public function log(s : String, ?lvl : LogLevel, ?pos : PosInfos) {
		if(lvl == null)
			lvl = NOTICE;
		if(Type.enumIndex(lvl) >= Type.enumIndex(level)) {
			var priority : String = switch(lvl) {
				case DEBUG:"user.debug";
				case INFO:"user.info";
				case NOTICE:"user.notice";
				case WARN:"user.warning";
				case ERROR:"user.err";
				case CRITICAL:"user.crit";
				case ALERT:"user.alert";
				case EMERG:"user.emerg";
			}
			var so : StringOutput = new StringOutput();
			format.writeLogMessage(so, this.serviceName, lvl, s, pos);
			Sys.command(loggerCmd, ["-i", "-p", priority, "-t",
				StringTools.urlEncode(serviceName), so.toString()]);
		}
	}
}
#end
