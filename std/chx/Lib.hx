package chx;

class Lib {
	#if( cpp || neko || lua )
	public static function load(lib : String, prim : String, nargs : Int) : Dynamic {
		#if cpp
		return cpp.Lib.load(lib, prim, nargs);
		#elseif neko
		return neko.Lib.load(lib, prim, nargs);
		#elseif lua
		return lua.Lib.load(lib, prim, nargs);
		#end
	}
	#end
}
