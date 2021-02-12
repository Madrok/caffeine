/*
 * Copyright (C)2005-2021 Haxe Foundation
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */

package chx.util;

#if macro
using Lambda;
using haxe.macro.Tools;
#end

class ObjectMerge {
	// /**
	//  * Typed combination of structures at compile time
	//  * ```haxe
	//  * using ObjectMerge;
	//  *
	//  * typedef Foo = { a: Int, b: Float }
	//  * typedef FooBar = { > Foo, bar: String };
	//  * static function callFoo() return { a: 42, b: 3.14 };
	//  * static function callBar() return { bar: "42" };
	//  *
	//  * class Main {
	//  *   static function main() {
	//  *     // you can use the macro with function results
	//  *     var fb: FooBar = callFoo().combine(callBar());
	//  *     // or with variables and anonymous structures
	//  *     var foo: Foo = callFoo();
	//  *     fb = foo.combine({ bar: "42" });
	//  *     // more parameters are allowed
	//  *     fb = {a: 111}.combine({b:13.1}, {bar: "happy hour"});
	//  *     // when several structures have the same field, the last wins.
	//  *     var fb2 = fb.combine({bar: "lucky strike"});
	//  *   }
	//  * }
	//  * ```
	//  * @param rest Additional structures to merge
	//  * @return Expr
	//  * @see https://code.haxe.org/category/macros/combine-objects.html
	//  */
	// public static macro function combine(rest : Array<Expr>) : Expr {
	// 	var pos = Context.currentPos();
	// 	var block = [];
	// 	var cnt = 1;
	// 	// since we want to allow duplicate field names, we use a Map. The last occurrence wins.
	// 	var all = new Map<String, {field : String, expr : Expr}>();
	// 	for (rx in rest) {
	// 		var trest = Context.typeof(rx);
	// 		switch(trest.follow()) {
	// 			case TAnonymous(_.get() => tr):
	// 				// for each parameter we create a tmp var with an unique name.
	// 				// we need a tmp var in the case, the parameter is the result of a complex expression.
	// 				var tmp = "tmp_" + cnt;
	// 				cnt++;
	// 				var extVar = macro $i{tmp};
	// 				block.push(macro var $tmp = $rx);
	// 				for (field in tr.fields) {
	// 					var fname = field.name;
	// 					all.set(fname, {field : fname, expr : macro $extVar.$fname});
	// 				}
	// 			default:
	// 				return Context.error("Object type expected instead of " + trest.toString(),
	// 					rx.pos);
	// 		}
	// 	}
	// 	var result = {expr : EObjectDecl(all.array()), pos : pos};
	// 	block.push(macro $result);
	// 	return macro $b{block};
	// }
	// /**
	//  * Supply a series of anonymous objects, and this macro will merge them into a single instance.
	//  * the macro preserves all of the typing info, so you still get completions, etc. on the merged object
	//  *
	//  * @author Justin Donaldson
	//  * @see https://gist.github.com/jdonaldson/a03722daad4e2842aa509ea910b60bc6
	//  */
	// public static macro function merge<T>(arr : Array<ExprOf<T>>) : Expr {
	// 	var fields = new Array<ObjectField>();
	// 	var seen = new Map<String, Int>();
	// 	var type = Context.followWithAbstracts(Context.typeof(a));
	// 	for (a in arr) {
	// 		switch(type) {
	// 			case TAnonymous(b):
	// 				{
	// 					var k = b.get();
	// 					for (f in k.fields) {
	// 						if(!seen.exists(f.name)) {
	// 							var name = f.name;
	// 							fields.push({
	// 								field : name,
	// 								expr : macro ${a}.$name
	// 							});
	// 							seen.set(name, 1);
	// 						}
	// 					}
	// 				}
	// 			default:
	// 				{
	// 					Context.error('unsupported: $type', a.pos);
	// 				}
	// 		}
	// 	}
	// 	return {expr : EObjectDecl(fields), pos : Context.currentPos()};
	// }

	/**
	 * Merge two anonymous objects. This is shallow, so any
	 * field on 'base' will be overwriten by 'ext'
	 * @param base base object
	 * @param ext object to merge onto base
	 */
	public static function shallowMerge(base : Dynamic, ext : Dynamic) {
		var res = Reflect.copy(base);
		for (f in Reflect.fields(ext))
			Reflect.setField(res, f, Reflect.field(ext, f));
		return res;
	}
}
