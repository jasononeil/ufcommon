/*
 * Copyright (C)2005-2012 Haxe Foundation
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
package ufcommon.remoting;

import haxe.remoting.AsyncConnection;
import haxe.remoting.HttpAsyncConnection;
import ufcommon.remoting.RemotingTrace;


/** Extension of class that allows traces to be sent.  On the server side, just make sure you 
    write to `Lib.printLn();` before `handleRequest(context)` is called.  

    This all relies on Haxe serialised data always being one line.

    A line beginning with hxr is the remoting call, a line beginning with hxt is a trace
	
	Any other line will throw an "Invalid response" error.
    */

class HttpAsyncConnectionWithTraces extends HttpAsyncConnection 
{
	override public function resolve( name ) : AsyncConnection {
		var c = new HttpAsyncConnectionWithTraces(__data,__path.copy());
		c.__path.push(name);
		return c;
	}

	// Code mostly copied from super class, but the onData() response has been modified to output traces
	override public function call( params : Array<Dynamic>, ?onResult : Dynamic -> Void ) {
		var h = new haxe.Http(__data.url);
		#if (neko && no_remoting_shutdown)
			h.noShutdown = true;
		#end
		var s = new haxe.Serializer();
		s.serialize(__path);
		s.serialize(params);
		h.setHeader("X-Haxe-Remoting","1");
		h.setParameter("__x",s.toString());
		var error = __data.error;
		h.onData = function( response : String ) {
			var ok = true;
			var ret = null;
			var stack:String = null;
			try {
				var hxrFound = false;
				for (line in response.split('\n'))
				{
					switch (line.substr(0,3))
					{
						case "hxr":
							var s = new haxe.Unserializer(line.substr(3));
							ret = s.unserialize();
							hxrFound = true;
						case "hxt":
							var s = new haxe.Unserializer(line.substr(3));
							var t:RemotingTrace = s.unserialize();
							haxe.Log.trace(t.v, t.p);
						case "hxs":
							var s = new haxe.Unserializer(line.substr(3));
							stack = s.unserialize();
						case "hxe":
							// Unserializing an exception will throw it
							var s = new haxe.Unserializer(line.substr(3));
							ret = s.unserialize();
						default:
							throw "Invalid line in response : '"+line+"'";
					}
				}
				if (hxrFound == false) throw "Invalid response, no hxr remoting line was found: " + response;
			} catch( err : Dynamic ) {

				// Pass the error to the error handler
				ok = false;
				ret = null;

				error({ err: err, stack: stack });
			}
			if( ok && onResult != null ) onResult(ret);
		};
		h.onError = error;
		h.request(true);
	}

	public static function urlConnect( url : String ) {
		return new HttpAsyncConnectionWithTraces({ url : url, error : function(e) throw e },[]);
	}

}
