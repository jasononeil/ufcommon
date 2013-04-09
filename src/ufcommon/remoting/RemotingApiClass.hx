package ufcommon.remoting;

/** This interface provides a build macro that will take some extra precautions to make
sure your Api class compiles successfully on the client as well as the server.

Basically, the build macro strips out private methods, and the method bodies of public methods,
so all that is left is the method signiature.

This way, the Proxy class will still be created successfully, but none of the server-side APIs
get tangled up in client side code.
*/
@:autoBuild(ufcommon.remoting.ApiMacros.buildApiClass())
interface RemotingApiClass
{

}