package ufcommon.remoting;

import haxe.remoting.HttpAsyncConnection;

/** A generic remoting client.
*/

class RemotingClient 
{
	var cnx:HttpAsyncConnection;
	public function new(url:String)
	{
		cnx = ufcommon.remoting.HttpAsyncConnectionWithTraces.urlConnect(url);
		cnx.setErrorHandler(processServerSideError); 
	}

	function processServerSideError(error:Dynamic)
	{
		try 
		{ 
			throw error; 
		}
		catch (e:Dynamic)
		{
			trace ('An error occured while making the remoting call: $e');
		}
	}
}