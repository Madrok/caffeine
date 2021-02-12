package chx.vm;

#if sys
typedef Thread = sys.thread.Thread;
#elseif js
import haxe.Timer;
import js.lib.Promise;
import jsasync.JSAsync;

using jsasync.JSAsyncTools;

private typedef StackItem<T> = {
	var resolve : (v : T)->Void;
	var reject : ((e : Dynamic)->Void);
	var block : Bool;
};

/**
 * On js, this pseudo-thread creates a timer that
 * starts in 1 ms. To use this, the jsasync library is required
 */
class Thread {
	public static var mainThread(default, null) : Thread;

	public static function create(callb : (t : Thread)->Promise<Bool>) : Thread {
		return new Thread(callb);
	}

	/**
	 *  the message queue
	 */
	private var msgQueue : Array<Dynamic> = [];

	/**
	 * promises awaiting messages
	 */
	private var promiseStack : Array<StackItem<()->Void>> = [];

	private function new(callb : (t : Thread)->Promise<Bool>) {
		if(callb != null) {
			var timer = new Timer(1);
			timer.run = JSAsync.jsasync(() -> {
				timer.stop();
				timer = null;
				callb(this)
					.jsawait();
			});
		}
	}

	public function sendMessage(msg : Dynamic) {
		msgQueue.push(msg);
		dispatch();
	}

	/**
	 * Read a message from the thread message stack. If there
	 * are no messages, and [block] is set to false, the
	 * promise will reject with a [BlockedException](../lang/BlockedException.html)
	 * @param block
	 * @return Promise<Dynamic>
	 */
	public function readMessage(block : Bool) : Promise<Dynamic> {
		return new Promise((resolve, reject) -> {
			promiseStack.push({resolve : resolve, reject : reject, block : block});
		});
		dispatch();
	}

	function dispatch() {
		while(msgQueue.length > 0) {
			if(promiseStack.length == 0)
				break;
			var m = msgQueue.shift();
			var p = promiseStack.shift();
			p.resolve(m);
		}
		// all queued messges resolved,
		// resolve any non-blocking reads
		var newStack = [];
		var modified = false;
		for (i in 0...promiseStack.length) {
			if(promiseStack[i].block == false) {
				modified = true;
				promiseStack[i].reject(new chx.lang.BlockedException());
			}
			else {
				newStack.push(promiseStack[i]);
			}
		}
		if(modified)
			promiseStack = newStack;
	}

	static function __init__() {
		mainThread = new Thread(null);
	}
}
#else // end js
#error
#end // end if sys
