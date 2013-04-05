package ufcommon.controller.admin;

import ufront.web.mvc.Controller;
import ufcommon.remoting.RemotingTrace;
import ufcommon.remoting.RemotingApiContext;
using Lambda;
using StringTools;

#if php import php.Lib; #end
#if neko import neko.Lib; #end
#if cpp import cpp.Lib; #end

class RemotingController extends Controller
{
    public static var remotingApi:RemotingApiContext;

    var context:haxe.remoting.Context;

    public function new()
    {
        super();

        // Set up the context.  Load the various APIs if 'remotingApi' has been set
    	context = new haxe.remoting.Context();
        if (remotingApi != null)
        {
            loadApi(remotingApi);
        }
    }

    public function run() 
    {
        // Set up a custom trace that will work with the HttpAsyncConnectionWithTraces controller
        var oldTrace = haxe.Log.trace;
        haxe.Log.trace = function (val:Dynamic, ?posInfo:haxe.PosInfos) {
            val = Std.string(val);
            if (posInfo.customParams != null)
            {
                posInfo.customParams = posInfo.customParams.map(function (v) { return Std.string(v); }).array();
            }
            var t:RemotingTrace = {
                v: val,
                p: posInfo
            }
            var serialisedTrace = haxe.Serializer.run(t);
            Lib.println("hxt" + serialisedTrace);
        }

        // Use cache on the data we serialise for remoting
        haxe.Serializer.USE_CACHE = true;

        // Handle the remoting request
        haxe.remoting.HttpConnection.handleRequest(context);

        haxe.Log.trace = oldTrace;
    }

    function loadApi(api:RemotingApiContext)
    {
        // Sys.println(api);
        for (fieldName in Reflect.fields(api))
        {
            var o = Reflect.field(api, fieldName);
            if (Reflect.isObject(o))
            {
                // this is an API field, add it.
                context.addObject(fieldName, o);
            }
        }
    }
}