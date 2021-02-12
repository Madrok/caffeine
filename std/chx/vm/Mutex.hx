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

package chx.vm;

#if sys
typedef Mutex = sys.thread.Mutex;
#elseif js
import js.lib.Error;
import js.lib.Promise;

typedef StackItem<T> = {
	var resolve : (v : T)->Void;
	var reject : ((e : Dynamic)->Void);
};

class Mutex {
	var acquired : Bool;

	var stack : Array<StackItem<()->Void>>;
	var resolver : ()->Void;

	public function new() {
		acquired = false;
		stack = new Array();
		resolver = null;
	}

	/**
	 * Returns a promise to a function that will release the mutex.
	 * Calling release() will also release it.
	 * @return Promise<()->Void> use this function (or release()) to release the mutex
	 */
	public function acquire() : Promise<()->Void> {
		var p = new Promise((resolve, reject) -> {
			stack.push({
				resolve : resolve,
				reject : reject
			});
		});
		if(!acquired)
			dispatch();
		return p;
	}

	function dispatch() {
		var p = stack.shift();
		if(p == null)
			return;
		acquired = true;
		resolver = () -> {
			acquired = false;
			dispatch();
		}
		p.resolve(resolver);
	}

	/**
	 * [Description]
	 * @return Promise<()->Void>
	 */
	public function tryAcquire() : Promise<()->Void> {
		if(!acquired)
			return acquire();
		return new Promise((resolve, reject) -> {
			reject(new Error('already acquired'));
		});
	}

	/**
		Releases an acquired mutex.
	**/
	public function release() {
		acquired = false;
		dispatch();
	}
}
#else
#error
#end
