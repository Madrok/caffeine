/*
 * Copyright (c) 2008-2021, The Caffeine-hx project contributors
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

package chx;

#if js
import js.lib.Promise;
#end

private enum Platform {
	NEKO;
	PHP;
	JS;
	NODEJS;
	CPP;
	LUA(ver : String);
	HASHLINK;
	PYTHON(ver : String);
	FLASH(ver : Int);
}

/**
 * Platform information and central common system functions.
 */
class Sys {
	public static var system(default, null) : String;
	public static var platform(default, null) : Platform;

	#if( js && !nodejs )
	public static var browserName(default, null) : String;
	public static var browserVersion(default, null) : String;
	public static var browserPlatform(default, null) : String;
	public static var hasCookies(default, null) : Bool;
	public static var userAgent(default, null) : String;
	public static var userLanguage(default, null) : String;
	#end

	/**
	 * Get the highest resolution time for the platform,
	 * as seconds since Unix Epoch time
	 * @return Float
	 */
	public static function time() : Float {
		#if sys
		return Sys.time();
		#elseif js
		return js.lib.Date.now() / 1000;
		#end
	}

	/**
	 * The operating system.
	 * @return String Windows, Linux, Mac, unknown
	 */
	public static function systemName() : String {
		return system;
	}

	/**
	 * The haxe platform compiled for.
	 * @return String Neko, Php, Javascript etc with version if available
	 */
	public static function platformName() : String {
		return switch(platform) {
			case NEKO:"Neko";
			case PHP:"Php";
			case JS:"Javascript";
			case NODEJS:"NodeJS";
			case CPP:"C++";
			case LUA(ver):"Lua " + ver;
			case HASHLINK:"Hashlink";
			case PYTHON(ver):"Python " + ver;
			case FLASH(ver):"Flash " + Std.string(ver);
		}
	}

	/**
	 * Sleep the specified number of seconds. For javascript, this
	 * returns a promise that can be awaited.
	 * @param seconds
	 */
	public static function sleep(seconds : Float) {
		#if sys
		Sys.sleep(seconds);
		#elseif js
		return new Promise((resolve, reject) -> {
			haxe.Timer.delay(untyped resolve, Std.int(seconds * 1000));
		});
		#else // end js
		#error
		#end
	}

	static function __init__() {
		system = "unknown";

		#if sys
		system = Sys.systemName();
		#if neko
		platform = NEKO;
		#elseif cpp
		platform = CPP;
		#elseif lua
		platform = LUA(lua.Lua._VERSION);
		#elseif php
		platform = PHP;
		#elseif java
		platform = JAVA;
		#elseif python
		platform = PYTHON(python.lib.Sys.version);
		#elseif hl
		platform = HASHLINK;
		#else
		#error
		#end
		#else // non 'sys' platforms
		#if js
		#if nodejs
		platform = NODEJS;
		#else
		platform = JS;
		var n = js.Syntax.code("navigator");
		browserName = n.appName; // Netscape
		browserVersion = n.appVersion; // 5.0 (X11; en-US)
		browserPlatform = n.platform; // Linux i686
		hasCookies = n.cookieEnabled;
		userAgent = n.userAgent; // Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.8.1.14) Gecko/20080420 Firefox/2.0.0.14
		userLanguage = n.userLanguage;

		var pl = browserPlatform.toLowerCase();
		if(pl.indexOf("linux") >= 0)
			system = "Linux";
		else if(pl.indexOf("mac") >= 0)
			system = "Mac";
		else
			system = "Windows";
		#end // if js
		#elseif flash
		var vs = flash.system.Capabilities.version;
		var pltVer = vs.split(" ");
		if(pltVer.length > 1) {
			var a = pltVer[1].split(",");
			platform = FLASH(Std.parseInt(a[0]));
		}
		else {
			platform = FLASH(0);
		}

		var ss = flash.system.Capabilities.os;
		if(StringTools.startsWith(ss.toLowerCase(), "windows"))
			system = "Windows";
		else if(StringTools.startsWith(ss.toLowerCase(), "linux"))
			system = "Linux";
		else
			system = "Mac";
		#else // end of flash
		#error // unknown other non 'sys' platform
		#end
		#end
	}
}

// Javascript navigator object:
// * appCodeName - The name of the browser's code such as "Mozilla".
// * appMinorVersion - The minor version number of the browser.
// * appName - The name of the browser such as "Microsoft Internet Explorer" or "Netscape Navigator".
// * appVersion - The version of the browser which may include a compatability value and operating system name.
// * cookieEnabled - A boolean value of true or false depending on whether cookies are enabled in the browser.
// * cpuClass - The type of CPU which may be "x86"
// * mimeTypes - An array of MIME type descriptive strings that are supported by the browser.
// * onLine - A boolean value of true or false.
// * opsProfile
// * platform - A description of the operating system platform.
// * plugins - An array of plug-ins supported by the browser and installed on the browser.
// * systemLanguage - The language being used such as "en-us".
// * userAgent - In my case it is "Mozilla/4.0 (compatible; MSIE 4.01; Windows 95)" which describes the browser associated user agent header.
// * userLanguage - The languge the user is using such as "en-us".
// * userProfile
