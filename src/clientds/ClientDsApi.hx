package clientds;

import sys.db.Types;
using tink.core.types.Outcome;
import ufcommon.remoting.RemotingApiClass;
import haxe.ds.StringMap;
import clientds.ClientDsResultSet;
import AppPermissions;
#if server 
	import sys.db.Manager;
	import ufcommon.auth.UserAuth;
#end 

class ClientDsApi implements RemotingApiClass
{
	public function new() {}

	/** 
	* Retrive sepcific objects from the database
	* 
	* As it's argument, it takes a StringMap, where each key represents the name of a model and
	* each value is an iterable of IDs for that model.  
	* 
	* Eg:
	*
	*  get([
	*  	"app.model.Farmer" => [33,34,35],
	*  	"app.model.Crop" => [1,2,5]
	*  ]);
	*
	* @param map, A StringMap as described above.
	* @return An outcome object, with a StringMap where key=modelName, value=List<Object> if it was 
	*  successful, or a String containing the error message if it failed.  If the query worked but 
	*  there were no results, it will return an empty list for that map key.  The return object may
	*  have objects you didn't request, if related objects where retrieved via the foreign keys etc.
	* 
	* With this API call, you will have to type things on the other side.  This hash this returns is
	* typed as a generic Object list for each model.  Using ClientDsResultSet can help with this.
	*/
	public function get(map:Map<String, Array<SUId>>):Outcome<ClientDsResultSet, String>
	{
		if (map == null) return "No map of models/IDs was supplied to ClientDsApi.getMany".asFailure();

		var returnMap = new ClientDsResultSet();

		try 
		{
			for (modelName in map.keys())
			{
				var ids = map.get(modelName);
				var manager = getManager(modelName);
				
				var tableName = Manager.quoteAny(untyped manager.table_name);
				var list = manager.unsafeObjects("SELECT * FROM `" + tableName + "` WHERE " + Manager.quoteList("id", ids), false);

				returnMap.set(modelName, list);
			}

			return returnMap.asSuccess();
		}
		catch (e:String)
		{
			return e.asFailure();
		}
	}

	/** 
	* Retrive all objects from a table (or many tables)
	* 
	* @param modelNames, An array containing all your model names.  eg ["app.models.User","app.models.Post"]
	* @return An outcome object, with a StringMap where key=modelName, value=List<Object> if it was 
	*  successful, or a String containing the error message if it failed.  If the query worked but 
	*  there were no results, it will return an empty list for that map key.
	* 
	* With this API call, you will have to type things on the other side.  This hash this returns just
	* contains a generic Object list for each model. Using ClientDsResultSet can help with this.
	*/
	public function all(modelNames:Array<String>):Outcome<ClientDsResultSet, String>
	{
		if (modelNames == null) return "No list of model names was supplied to ClientDsApi.getAllFromModels".asFailure();

		var returnMap = new ClientDsResultSet();

		try 
		{
			for (modelName in modelNames)
			{
				var manager = getManager(modelName);
				var list = manager.all();
				returnMap.set(modelName, list);
			}

			return returnMap.asSuccess();
		}
		catch (e:String)
		{
			return e.asFailure();
		}
	}

	/** 
	* Retrive objects that match given criteria
	* 
	* As it's argument, it takes a StringMap, where each key represents the name of a model and
	* each value is a object of properties to match, similar to Manager.dynamicSearch();
	* 
	* Eg:
	*
	*  get([
	*  	"app.model.Farmer" => { age: 46, state: "WA" },
	*  	"app.model.Crop" => { type: "wheat" }
	*  ]);
	*
	* @param map, A StringMap as described above.
	* @return An outcome object, with a StringMap where key=modelName, value=List<Object> if it was 
	*  successful, or a String containing the error message if it failed.  If the query worked but 
	*  there were no results, it will return an empty list for that map key.
	* 
	* With this API call, you will have to type things on the other side.  This hash this returns just
	* contains a generic Object list for each model. Using ClientDsResultSet can help with this.
	*/
	public function search(map:StringMap<{}>):Outcome<ClientDsResultSet, String>
	{
		if (map == null) return "No list of model names was supplied to ClientDsApi.getAllFromModels".asFailure();

		var returnMap = new ClientDsResultSet();

		try 
		{
			for (modelName in map.keys())
			{
				var criteria = map.get(modelName);
				var manager = getManager(modelName);
				var list = manager.dynamicSearch(criteria);
				returnMap.set(modelName, list);
			}

			return returnMap.asSuccess();
		}
		catch (e:String)
		{
			return e.asFailure();
		}
	}

	/** 
	* Save some objects to the database by calling save() on each one.
	* 
	* @param map of objects to save: "aModelName" => [aObject1, aObject2], "bModelName" => [bObject1, bObject2]
	* @return This returns a StringMap with the same keys as the original, and an array for each value, with the
	*   same number of items as the original arrays.  Inside the array, at the same location, is an outcome.  If
	*   the save was successful, the outcome contains the ID of the object that was saved.  If the save failed,
	*   the outcome contains the error message for that save.
	*   
	* Currently this does no optimisations for bulk SQL inserts... not sure if I want that, as it would skip our save()
	* method which does validation/permission checks.
	*/
	public function save(map:Map<String, Array<ufcommon.db.Object>>):StringMap<Array<Outcome<SUId, String>>>
	{
		if (map == null) return new StringMap();

		var retMap = new StringMap();

		for (modelName in map.keys())
		{
			var objects = map.get(modelName);
			if (objects != null)
			{
				var a:Array<Outcome<SUId, String>> = [];
				for (o in map.get(modelName))
				{
					try 
					{
						o.save();
						a.push(o.id.asSuccess());
					}
					catch (e:String)
					{
						a.push(e.asFailure());
					}
				}
				retMap.set(modelName, a);
			}
		}

		return retMap;
	}

	/** 
	* Delete some objects from the database by calling delete() on each one
	* 
	* @param map of objects to delete: "aModelName" => [1, 2], "bModelName" => [1, 2]
	* @return This returns a StringMap with the same keys as the original, and an array for each value, with the
	*   same number of items as the original arrays.  Inside the array, at the same location, is an outcome.  If
	*   the save was successful, the outcome contains the ID of the object that was saved.  If the save failed,
	*   the outcome contains the error message for that save.
	*   
	* Currently this does no optimisations for bulk SQL removals... not sure if I want that, as it would skip 
	* any onDelete() callbacks (not that they're even implemented yet...)
	*/
	@:access(sys.db.Manager)
	public function delete(map:Map<String, Array<SUId>>):StringMap<Array<Outcome<SUId, String>>>
	{
		if (map == null) return new StringMap();

		var retMap = new StringMap();

		for (modelName in map.keys())
		{
			var objects = map.get(modelName);
			var manager = getManager(modelName);
			if (objects != null)
			{
				var a:Array<Outcome<SUId, String>> = [];
				for (id in map.get(modelName))
				{
					try 
					{
						var tableName = manager.table_name;
						var quotedID = manager.quoteField('$id');
						manager.unsafeDelete('DELETE FROM $tableName WHERE `id` = $quotedID');
						a.push(id.asSuccess());
					}
					catch (e:String)
					{
						a.push(e.asFailure());
					}
				}
				retMap.set(modelName, a);
			}
		}

		return retMap;
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