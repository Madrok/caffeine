class RunTest {
	public static var config = {
		stdPath : "/Users/russell/devel/caffeine/std",
		haxe : "/usr/local/bin/haxe",
		commonBuild : "testCommon.hxml",
		classPaths : []
	};

	public static function main() {
		var args = Sys.args();
		if(args.length == 0)
			usage();

		try {
			var txt = sys.io.File
				.read(".runtest_cfg", false)
				.readAll()
				.toString();
			var o = haxe.Json.parse(txt);
			RunTest.config = chx.util.ObjectMerge.shallowMerge(RunTest.config, o);
		}
		catch(e) {
			Sys.println("Error: " + e.toString());
			Sys.exit(1);
		}

		var newArgs = [];
		for (i in 0...config.classPaths.length) {
			newArgs.push("-cp");
			newArgs.push(config.classPaths[i]);
		}
		newArgs.push("--main");
		newArgs.push(args.shift());
		for (i in 0...args.length) {
			newArgs.push("-L");
			newArgs.push(args[i]);
		}
		newArgs.push(config.commonBuild);
		trace(newArgs);
		Sys.putEnv("HAXE_STD_PATH", config.stdPath);
		Sys.command(config.haxe, newArgs);
	}

	static function usage() {
		Sys.println("usage:");
		Sys.println("runtest mainclass [additionalClasspaths...]");
		Sys.println("- this also pulls in the config file .runtest_cfg");
		Sys.exit(1);
	}
}
