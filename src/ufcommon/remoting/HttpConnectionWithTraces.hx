package ufcommon.remoting;

import haxe.remoting.Context;
using StringTools;
import haxe.CallStack;
#if neko 
import neko.Web;
import neko.Lib;
#elseif php 
import php.Web;
import php.Lib;
#end

/**
* Adds extra info (traces, stacktrace) to the remoting output.
* 
* "hxr" -> traditional remoting response
* "hxt" -> traces during remoting call
* "hxe" -> serialized exception if one was uncaught
* "hxs" -> stack items if there was an error
*
* To be used in the same way as haxe.remoting.HttpConnection
*
* To be used in conjunction with HttpAsyncConnectionWithTraces on the client.
*/
class HttpConnectionWithTraces
{
	public static function handleRequest( ctx : Context ) {
		
        // Check if this is a remoting request
		var v = Web.getParams().get("__x");
		if( Web.getClientHeader("X-Haxe-Remoting") == null || v == null )
			return false;

		// Set up a custom trace that will work with the HttpAsyncConnectionWithTraces controller
        var oldTrace = haxe.Log.trace;
        haxe.Log.trace = function (val:Dynamic, ?posInfo:haxe.PosInfos) {
            val = Std.string(val);
            if (posInfo.customParams != null)
            {
                posInfo.customParams = posInfo.customParams.map(function (v) { return Std.string(v); });
            }
            var t:RemotingTrace = {
                v: val,
                p: posInfo
            }
            var serializedTrace = haxe.Serializer.run(t);
            Lib.println("hxt" + serializedTrace);
        }

        // Handle the request
		Lib.print(processRequest(v,ctx));

		// Restore the traces 
		haxe.Log.trace = oldTrace;

		return true;
	}

	public static function processRequest( requestData : String, ctx : Context ) : String {
		try {
			var u = new haxe.Unserializer(requestData);
			var path = u.unserialize();
			var args = u.unserialize();
			var data = ctx.call(path,args);
			var s = new haxe.Serializer();
			s.serialize(data);
			return "hxr" + s.toString();
		} catch( e : Dynamic ) {
			// Serialize the stack trace
            var err = Std.string(e).htmlEscape();
            var exceptionStack = CallStack.toString(CallStack.exceptionStack());
            var serializedStack = haxe.Serializer.run(exceptionStack);
            Lib.println("hxs" + serializedStack);

			// Serialize the exception
			var s = new haxe.Serializer();
			s.serializeException(e);
			return "hxe" + s.toString();
		}
	}
}