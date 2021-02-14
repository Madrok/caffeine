/*
 * Copyright (c) 2009-2021, The Caffeine-hx project contributors
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

package chx.vm;

/**
 * A lock class that works on all platforms. Serialization of locks will
 * leave them in an undefined state, so they should be replaced.
 */
#if( target.threaded )
typedef Lock = sys.thread.Lock;
#elseif js
import chx.Sys;
import haxe.Timer;
import js.lib.Error;
import js.lib.Promise;

private typedef StackItem<T> = {
	var resolve : (v : T)->Void;
	var reject : ((e : Dynamic)->Void);
	var timeout : Float;
};

class Lock {
	var releaseCount : Int;
	var stack : Array<StackItem<()->Void>>;
	var resolver : ()->Void;
	var t : Timer;
	var freq : Float = 999.9;

	public function new() {
		releaseCount = 0;
		stack = new Array();
		resolver = null;
	}

	/**
	 * [Description]
	 * @param timeout maximum time to wait, in seconds, or 0 to wait forever
	 * @return Promise<()->Void>  use this function (or release()) to release the lock
	 */
	public function wait(?timeout : Float) : Promise<()->Void> {
		var waitS : Float = (timeout != null) ? timeout : 0;

		createMonitor(waitS);
		var p = new Promise((resolve, reject) -> {
			stack.push({resolve : resolve,
				reject : reject,
				timeout : (waitS > 0) ? Sys.time() + waitS : 0
			});
		});
		if(releaseCount > 0)
			dispatch();
		return p;
	}

	public function release() {
		releaseCount++;
		dispatch();
	}

	function dispatch() {
		var p = stack.shift();
		if(p == null)
			return;
		releaseCount--;
		resolver = () -> {
			releaseCount++;
			dispatch();
		}
		p.resolve(resolver);
	}

	function createMonitor(timeout : Float) {
		if(timeout == 0)
			return;
		var tms = timeout / 1000;
		if(t == null) {
			freq = timeout;
			t = new Timer(Std.int(timeout / 1000));
			t.run = monitor;
		}
		else {
			if(timeout < freq) {
				// a faster timeout needed
				t.stop();
				t = null;
				createMonitor(timeout);
			}
		}
	}

	function monitor() {
		if(stack.length == 0) {
			// nothing left to monitor
			if(t != null) {
				t.stop();
				t = null;
				freq = 999;
			}
			return;
		}
		var now = Sys.time();
		var newStack = [];
		var modified = false;
		for (i in 0...stack.length) {
			if(stack[i].timeout > 0 && stack[i].timeout <= now) {
				modified = true;
				stack[i].reject(new Error('timeout'));
			}
			else {
				newStack.push(stack[i]);
			}
		}
		if(modified)
			stack = newStack;
	}
}
#else
#error
#end
