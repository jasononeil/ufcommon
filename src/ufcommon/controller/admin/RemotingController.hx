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
        // Handle the remoting request
        ufcommon.remoting.HttpConnectionWithTraces.handleRequest(context);
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