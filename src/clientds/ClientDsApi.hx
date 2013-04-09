package clientds;

import sys.db.Types;
using tink.core.types.Outcome;
import ufcommon.remoting.RemotingApiClass;
import AppPermissions;
#if server 
	import sys.db.Manager;
	import ufcommon.auth.UserAuth;
#end 

class ClientDsApi implements RemotingApiClass
{
	public function new() {}

	public function get<T:ufcommon.db.Object>(modelName:String, id:SUId):Outcome<T, String>
	{
		UserAuth.requirePermission(AccessStaffArea);

		try 
		{
			var manager = getManager(modelName);
			var obj:T = cast manager.unsafeGet(id);
			
			// If no obj, fail.  Otherwise, return as success
			if (obj == null)
				throw 'No item in $modelName had the ID $id';
			else 
				return obj.asSuccess();
		} 
		catch (e:String) 
		{
			return e.asFailure();
		}
	}

	#if server 
		function getManager(modelName:String):Manager<ufcommon.db.Object>
		{
			var modelCl:Class<Dynamic> = Type.resolveClass(modelName);

			// If class wasn't found, return failure
			if (modelCl == null)
				throw 'The model $modelName was not found';

			// If there is no "manager", return failure
			if (Reflect.hasField(modelCl, "manager") == false)
				throw 'The model $modelName had no field "manager"';

			// Try to create an instance of the manager
			var manager:Manager<ufcommon.db.Object> = Reflect.field(modelCl, "manager");

			// Check it's a valid manager
			if (!Std.is(manager, sys.db.Manager)) throw 'The manager for $modelName was not valid.';

			// Hopefully by this point everything is safe to cast
			return cast manager;
		}
	#end
}