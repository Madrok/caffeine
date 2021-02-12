import sys.net.Host;

class TestSocket {
	public static function main() {
		testConnectFail();
	}

	public static function testConnectFail() {
		trace("running testConnectFail");
		var s = new chx.net.TcpSocket();
		// s.setBlocking(false);
		s.setTimeout(2);
		try {
			s.connect(new Host("127.0.0.2"), 3941);
		}
		catch(e:chx.lang.IOException) {
			trace("passed");
		}
	}
}
