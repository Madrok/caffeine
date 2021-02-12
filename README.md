# caffeine
A replacement standard library for Haxe 4.2+. This may be just for my own personal academic interest, but
if you have code that should be in a standard library, and like to live on the wild side, contribute today! 

## History
I wrote Caffeine-hx and chxdoc back in 2007-09, but life took me in other directions. Having picked up haxe again for some projects, 
and then seeing the exciting changes in 4.2 (oh wow, abstract classes? Rest paramaeters?...), I thought I'd throw it back online
for consideration.

### Old sources
Yes, some of this is old. It probably doesn't work well anymore. But it's here. Specifically I'm talking about the
dll extensions in dll_src. These are for supplemental libraries to support the various methods in chx.*, and were 
only targetting neko at the time. However, with a little love and affection, they can easily be made to work with
cpp, python, node, lua and whatever platform I just missed. There's nothing like using the speed of native openssl!

## Goals
* Remove flash. It's over. Give up already.
* Unify exceptions and classes across platforms. I don't want to catch new unknown things just because I switch my program to run on neko/python/node/cpp instead of hashlink/lua/java.
* Reorganize. Some things, well, they need to be in better places.
* add, add, add. There's a significant lack of good functionality in the haxe standard library
* Interfaces. There's a keyword *implements*, why don't we try using it for a change
* abstract. Damn near every decent language has that kind of class. Now haxe does too. Kill all the foo() { throw "not implemented" } nonsense


