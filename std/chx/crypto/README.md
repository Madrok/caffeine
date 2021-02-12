# Crypt
The haxe crypt functions have been moved here, however they need to be reconciled with
all the work done on actual crypt functions from he original caffeine-hx

## TODO issues
* Since haxe std library has no crypt functions in haxe.crypto (say what? well *maybe* you could count Base64 as a crypt, but only if you're like 12 years old), all the old caffeine crypt files are direct in crypt/
* There's a base64 in both encoding/ and formats/. 
* Don't need an encoding and formats directory. Pick one.


## Copyrights

The code in chx.crypto is either a copy or derivitive of The Haxe sources, or derived from code
by Henri Torgemane. Code derived from work by Henri is subject to the following copyright
```
/*
 * Copyright (c) 2008, The Caffeine-hx project contributors
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
```
/*
 * Copyright (c) 2007 Henri Torgemane
 * All Rights Reserved.
 *
 * BigInteger, RSA, Random and ARC4 are derivative works of the jsbn library
 * (http://www-cs-students.stanford.edu/~tjw/jsbn/)
 * The jsbn library is Copyright (c) 2003-2005  Tom Wu (tjw@cs.Stanford.EDU)
 *
 * MD5, SHA1, and SHA256 are derivative works (http://pajhome.org.uk/crypt/md5/)
 * Those are Copyright (c) 1998-2002 Paul Johnston & Contributors (paj@pajhome.org.uk)
 *
 * SHA256 is a derivative work of jsSHA2 (http://anmar.eu.org/projects/jssha2/)
 * jsSHA2 is Copyright (c) 2003-2004 Angel Marin (anmar@gmx.net)
 *
 * AESKey is a derivative work of aestable.c (http://www.geocities.com/malbrain/aestable_c.html)
 * aestable.c is Copyright (c) Karl Malbrain (malbrain@yahoo.com)
 *
 * BlowFishKey, DESKey and TripeDESKey are derivative works of the Bouncy Castle Crypto Package (http://www.bouncycastle.org)
 * Those are Copyright (c) 2000-2004 The Legion Of The Bouncy Castle
 *
 * Base64 is copyright (c) 2006 Steve Webster (http://dynamicflash.com/goodies/base64)
 *
 * Redistribution and use in source and binary forms, with or without modification, 
 * are permitted provided that the following conditions are met:
 *
 * Redistributions of source code must retain the above copyright notice, this list 
 * of conditions and the following disclaimer. Redistributions in binary form must 
 * reproduce the above copyright notice, this list of conditions and the following 
 * disclaimer in the documentation and/or other materials provided with the distribution.
 *
 * Neither the name of the author nor the names of its contributors may be used to endorse
 * or promote products derived from this software without specific prior written permission.
 *
 * THE SOFTWARE IS PROVIDED "AS-IS" AND WITHOUT WARRANTY OF ANY KIND, 
 * EXPRESS, IMPLIED OR OTHERWISE, INCLUDING WITHOUT LIMITATION, ANY 
 * WARRANTY OF MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE.  
 *
 * IN NO EVENT SHALL TOM WU BE LIABLE FOR ANY SPECIAL, INCIDENTAL,
 * INDIRECT OR CONSEQUENTIAL DAMAGES OF ANY KIND, OR ANY DAMAGES WHATSOEVER
 * RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER OR NOT ADVISED OF
 * THE POSSIBILITY OF DAMAGE, AND ON ANY THEORY OF LIABILITY, ARISING OUT
 * OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *
 */
```

Before using, please ensure you review the licenses for the code origins.