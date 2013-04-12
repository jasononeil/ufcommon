package clientds;

import app.Api;
import ufcommon.remoting.*;
using clientds.ClientDsResultSet;
using tink.core.types.Outcome;

#if client
	import ufcommon.db.Types;
	import promhx.Promise;
	import haxe.ds.*;
	using Lambda;

	class ClientDs<T:ufcommon.db.Object> implements RequireApiProxy<ClientDsApi>
	{
		//
		// Factory
		//

		/** 
		* Get (or create) a ClientDS for the given model.  
		*
		* If you're using ufcommon.db.Object, this will be attached to your models on the client in the same way
		* that a manager is attached on the server, essentially:
		*
		*     static var clientDS:ClientDs<MyModel> = ClientDs.getClientDsFor(MyModel);
		* 
		* @param The model to get a client for
		* @return The ClientDS (DataStore) for that model
		*/
		public static function getClientDsFor<W:ufcommon.db.Object>(model:Class<W>):ClientDs<W>
		{
			var name = Type.getClassName(model);
			if (clientDataStores.exists(name))
			{
				return cast clientDataStores.get(name);
			}
			else 
			{
				var ds = new ClientDs(model);
				clientDataStores.set(name, cast ds);
				return ds;
			}
		}
		static var clientDataStores:StringMap<ClientDs<ufcommon.db.Object>>;

		//
		// API
		//
		public static var api:clientds.ClientDsApiProxy;

		//
		// Member variables / methods
		//

		var model:Class<T>;
		var modelName:String;
		var ds:IntMap<Promise<Null<T>>>;
		var allPromise:Promise<IntMap<T>>;
		var searchPromises:ObjectMap<{}, Promise<IntMap<T>>>;

		/** Constructor is private.  Please use ClientDS.getClientDsFor(model) to create */
		function new(model:Class<T>)
		{

			this.model = model;
			this.modelName = Type.getClassName(model);
			this.ds = new IntMap();
			this.allPromise = null;
			this.searchPromises = new ObjectMap();
		}

		/** 
		* Fetch an object for the given ID.  
		*
		* @param The id of the object to get.
		* @return This returns a promise.  When the object is received (or if it's already cached), the promise
		*   will be fulfilled and your code will execute. If the object was not found, the promise will resolve as null.
		* @throws (String) an error message, if ClientDs.api has not been set.
		* @reject (String) an error message if the object could not be retrieved from the server
		*/
		public function get(id:SUId):Promise<Null<T>>
		{
			if (api == null) throw "Please set static property 'api' before using ClientDs";
			
			if (ds.exists(id)) 
			{ 
				// If it already exists, return that promise.
				trace ('Found cache for $modelName[$id]'); 
				return ds.get(id); 
			}
			else 
			{
				// Else, create the promise
				var p = new Promise<T>();
				ds.set(id, p);
				
				if (allPromise != null)
				{
					// If an existing call to all() has been made, wait for that
					trace ('Will wait for $modelName[$id] to be retrieved from all() promise');
					allPromise.then(function (list) {
						trace ('Retrieved $modelName[$id] via call to all()');
						var obj = list.filter(function (o) return o.id == id).first();
						p.resolve(obj);
					});
				}
				else 
				{
					// Otherwise, create a new call just to retrieve this object
					trace ('Begin retrieval of $modelName[$id]');
					var map = [ modelName => [id] ];
					api.get(map, function (result) {
						switch (result)
						{
							case Success(resultSet):
								trace ('Retrieved $modelName[$id] successfully');
								processResultSet(resultSet);
							case Failure(msg):
								p.reject("ClientDs, retrieving object from API failed: " + msg);
						}
					});
				}
				return p;
			}
		}

		/** 
		* Fetch a bunch of objects given a bunch of IDs.
		*
		* This will try to be clever and not request objects that are already in the cache or being processed.
		*
		* Promises will be created for each ID so they are available in the cache.  The promise that
		* is returned here will only fire when every object is available.
		* 
		* @param The ids of the model to get.  eg clientDS.getMany([1,2,3,4]);
		* @return The promise returned is for an IntMap containing all of the matched objects.  The
		*    key is the ID, the value the actual object.  If an object was not found, it will not be
		*    included in the list.
		* @throws (String) an error message, if ClientDs.api has not been set.
		* @reject (String) an error message if objects could not be retrieved from the server
		*/
		public function getMany(ids:Iterable<SUId>):Promise<IntMap<T>>
		{
			if (api == null) throw "Please set static property 'api' before using ClientDs";
			
			var unfulfilledPromises = ids.array();
			var newRequests = unfulfilledPromises.filter(function (id) return ds.exists(id) == false);
			var existingPromises = unfulfilledPromises.filter(function (id) return ds.exists(id) == true);
			var list = new IntMap();

			// Create a promise for the overall list
			var listProm = new Promise<IntMap<T>>();

			// Create a promise for each of the new requests
			for (id in newRequests)
			{
				ds.set(id, new Promise());
			}

			// As the existing promises are fulfilled, tick them off
			var allCurrentPromises = [];
			for (id in ids)
			{
				var p = ds.get(id);
				allCurrentPromises.push(p);
				p.then(function (obj) { 
					// Add the object to our return list, and remove it from our list of unfulfilled promises.  
					list.set(id, obj);
					unfulfilledPromises.remove(id); 
					// Once all promises are fulfilled
					if (unfulfilledPromises.length == 0)
					{
						// Faith in humanity, restored
						listProm.resolve(list);
					}
				});
			}

			if (allPromise != null)
			{
				// If an existing call to all() has been made, wait for that
				allPromise.then(function (all) {
					// When that resolves, each instance will resolve, and our list as a whole should resolve...
					// If not, it means some of the IDs did not exist. Just resolve with the list that did exist...
					// list() will be populated as each individual one was added to the cache, so we can just add that
					if (Promise.allSet(allCurrentPromises) == false) { listProm.resolve(list); }
				});
			}
			else
			{
				// Otherwise, create a new call just to retrieve these specific objects
				var map = [ modelName => newRequests ];
				api.get(map, function (result) {
					switch (result)
					{
						case Success(resultSet):
							processResultSet(resultSet);
							// After processing, all promises should be found.  If not, it means some of the IDs
							// did not exist. Just resolve with the list that did exist...
							if (Promise.allSet(allCurrentPromises) == false) { listProm.resolve(list); }
						case Failure(msg):
							listProm.reject("ClientDs, retrieving objects from API failed: " + msg);
					}
				});
			}

			// Return the promise while we wait for everything to resolve.
			return listProm;
		}

		/** 
		* Fetch all the objects belonging to a given model. 
		*
		* Promises will be created for each ID so they are available in the cache.  The promise that
		* is returned here will only fire when every object is available.  If some of the objects 
		* are already in the cache, they will be reloaded. 
		*
		* If you have already called this and it is in the cache, or currently processing, the same
		* promise will be returned.  Call refreshAll() to get a fresh copy.
		* 
		* @return The promise returned is for an IntMap containing all of the objects in this model.  
		*    The key is the ID, the value the actual object.
		* @throws (String) an error message, if ClientDs.api has not been set.
		* @reject (String) an error message, if there was an error retrieving objects from the API
		*/
		public function all():Promise<IntMap<T>>
		{
			if (allPromise == null)
			{
				if (api == null) throw "Please set static property 'api' before using ClientDs";
				
				allPromise = new Promise();

				// Make the API call
				api.all([modelName], function (result) {
					switch (result)
					{
						case Success(rs):

							// Process each and resolve individual promises
							processResultSet(rs);

							// Build the IntMap for the "allPromise"
							var intMap = new IntMap();
							for (item in rs.items(cast model))
							{
								intMap.set(item.id, item);
							}
							allPromise.resolve(cast intMap);

						case Failure(msg):
							allPromise.reject("ClientDs, retrieving objects from API failed: " + msg);
					}
				});
			}

			return allPromise;
		}

		/** 
		* Fetch all the objects belonging that match the search criteria. 
		*
		* If allPromise is available, (ie, if you have called all()), then we will filter objects on the
		* client side.  Otherwise, we will call Manager.dynamicSearch() on the server. 
		* 
		* Promises will be created for each ID so they are available in the cache.  The promise that
		* is returned here will fire when all matched objects are available.  If some of the 
		* matching objects are already in the cache, they will be reloaded. 
		* 
		* If you have already searched for this and it is in the cache, or currently processing, 
		* the same promise will be returned.  Use refreshSearch() to get a fresh copy.
		* 
		* @param A dynamic object specifying the criteria to match.  Usage is the same as manager.dynamicSearch()
		* @return The promise returned is for an IntMap containing all of the matched objects.  The
		*    key is the ID, the value the actual object.
		* @throws (String) an error message, if ClientDs.api has not been set.
		* @reject (String) an error message, if there was an error retrieving objects from the API
		*/
		public function search(criteria:{}):Promise<IntMap<T>>
		{
			var prom:Promise<IntMap<T>>;

			if (searchPromises.exists(criteria))
			{
				// Do nothing, we'll just use the existing promise

				prom = searchPromises.get(criteria);
			}
			else if (allPromise != null)
			{
				// Wait for the entire list to load, and then do a filter

				prom = new Promise();
				allPromise.then(function (intMap) {
					var matches = new IntMap();
					for (obj in intMap)
					{
						var match = true;
						for (field in Reflect.fields(criteria))
						{
							var criteriaValue = Reflect.field(criteria, field);
							var objValue = Reflect.getProperty(obj, field);
							if (criteriaValue != objValue)
							{
								match = false;
								break;
							}
						}
						if (match)
						{
							matches.set(obj.id, obj);
						}
					}
					prom.resolve(matches);
				});
			}
			else
			{
				// No existing cache, so do a call to the API, which will do a dynamicSearch()

				if (api == null) throw "Please set static property 'api' before using ClientDs";
				
				prom = new Promise();
				searchPromises.set(criteria, prom);

				// Make the API call
				var map:StringMap<{}> = new StringMap();
				map.set(modelName, criteria);
				api.search(map, function (result) {
					switch (result)
					{
						case Success(rs):

							// Process each and resolve individual promises
							processResultSet(rs);

							// Build the IntMap for the "allPromise"
							var intMap = new IntMap();
							for (item in rs.items(cast model))
							{
								intMap.set(item.id, item);
							}
							prom.resolve(cast intMap);

						case Failure(msg):
							prom.reject("ClientDs, retrieving objects from API failed: " + msg);
					}
				});
			}
			return prom;
		}

		/**
		* Save the given object to the server on the database.
		*
		* This calls save(), so will either insert() or update().  All validation and permission checks will still occur
		* on the server.
		*
		* @param The object to save
		* @return A promise containing the same object.  The 'id' field will be updated if the object was freshly inserted.
		* @reject (String) Any error message.  Could be to do with database access, permission failures, validation failures etc.
		*/
		public function save(o:T):Promise<T>
		{
			if (api == null) throw "Please set static property 'api' before using ClientDs";

			var p = new Promise();
			var map = [ modelName => [o] ];
			api.save(cast map, function (result) {
				var outcome = result.get(modelName)[0];
				switch (outcome)
				{
					case Success(id):
						o.id = id;
						p.resolve(o);
					case Failure(msg):
						p.reject('Failed to delete $o: $msg');
				}
			});
			return p;
		}

		/**
		* Delete the given object from the server
		*
		* This calls delete() on the server, so all permission checks will still occur on the server.
		*
		* @param The ID of the object to delete
		* @return A promise containing the same ID.  
		* @reject (String) Any error message.  Could be to do with database access, permission failures etc.
		*/
		public function delete(id:SUId):Promise<SUId>
		{
			if (api == null) throw "Please set static property 'api' before using ClientDs";

			var p = new Promise();
			var map = [ modelName => [id] ];
			api.delete(map, function (result) {
				var outcome = result.get(modelName)[0];
				switch (outcome)
				{
					case Success(id):
						p.resolve(id);
					case Failure(msg):
						p.reject('Failed to delete $modelName[$id]: $msg');
				}
			});
			return p;
		}

		/** Same as get(id), but deletes the cache for that item first. */
		public function refresh(id:SUId):Promise<Null<T>>
		{
			ds.remove(id);
			return get(id);
		}

		/** Same as all(), but deletes the cache for that whole model first. */
		public function refreshAll():Promise<IntMap<T>>
		{
			allPromise = null;
			return all();
		}

		/** Same as search(criteria), but deletes any matching cached search first. */
		public function refreshSearch(criteria:{}):Promise<IntMap<T>>
		{
			allPromise = null;
			searchPromises.remove(criteria);
			return search(criteria);
		}

		//
		// Static methods
		//

		/** 
		* Get all() from several different models and add the results to the data store.
		*
		* This will make a fresh API call, and will replace any existing cached data.
		*
		* @param An array of the models/classes you wish to retrieve objects from
		* @return A promise for when all the models have been fetched.
		* @throws (String) an error message, if ClientDs.api has not been set.
		* @reject (String) an error message if objects could not be retrieved from the server
		*/
		public static function getAllObjects(models:Array<Class<ufcommon.db.Object>>):Promise<ClientDsResultSet>
		{
			if (api == null) throw "Please set static property 'api' before using ClientDs";

			var p = new Promise();

			// Make the API call
			var modelNames = models.map(function (m) return Type.getClassName(m));
			api.all(modelNames, function (result) {
				switch (result)
				{
					case Success(rs):

						// Process each and resolve individual promises
						var map = processResultSet(rs);
						
						// Resolve the allPromise for each clientDS
						for (modelName in map.keys())
						{
							var model = Type.resolveClass(modelName);
							var modelDS = getClientDsFor(model);

							// If the promise has already been resolved, do a new one
							if (Promise.allSet([modelDS.allPromise])) modelDS.allPromise = new Promise();
							modelDS.allPromise.resolve(map.get(modelName));
						}
						
						// Resolve the overall promise
						p.resolve(rs);

					case Failure(msg):
						p.reject("ClientDs, retrieving objects from API failed: " + msg);
				}
			});

			// Set up promises for each model, if they aren't there already
			for (model in models)
			{
				var modelDS = getClientDsFor(model);
				if (modelDS.allPromise == null) modelDS.allPromise = new Promise();
			}

			return p;
		}

		/** 
		* Perform a search on several different models and add the results to the data store.
		*
		* This will make a fresh API call, and will replace any existing cached data.  New data will
		* be added to the cache.
		*
		* @param A StringMap, with key=modelName, value={criteria}.  Value is an anonymous object used to match items, same as manager.dynamnicSearch()
		* @return A promise for when all the models have been fetched.
		* @throws (String) an error message, if ClientDs.api has not been set.
		* @reject (String) an error message if objects could not be retrieved from the server
		*/
		public static function searchForObjects(inMap:StringMap<{}>):Promise<ClientDsResultSet>
		{
			if (api == null) throw "Please set static property 'api' before using ClientDs";


			// Set up promises
			var p = new Promise();	// Overall promise
			for (modelName in inMap.keys())	// For each search
			{
				var model = Type.resolveClass(modelName);
				var modelDS = getClientDsFor(model);
				var criteria = inMap.get(modelName);

				if (modelDS.searchPromises.exists(criteria) == false)
				{
					modelDS.searchPromises.set(criteria, new Promise());
				}
			}

			// Make the API call
			api.search(inMap, function (result) {
				switch (result)
				{
					case Success(rs):

						// Process each and resolve individual item promises
						var rsMap = processResultSet(rs);
						
						// Resolve each search promise on it's ClientDS
						for (modelName in rsMap.keys())
						{
							var model = Type.resolveClass(modelName);
							var modelDS = getClientDsFor(model);

							var criteria = inMap.get(modelName);
							var searchProm = modelDS.searchPromises.get(criteria);
							if (Promise.allSet([searchProm]))
							{
								// If the promise has already been resolved, do a new one
								searchProm = new Promise();
								modelDS.searchPromises.set(criteria, searchProm);
							}
							searchProm.resolve(rsMap.get(modelName));
						}

						// Resolve the overall promise
						p.resolve(rs);

					case Failure(msg):
						p.reject("ClientDs, retrieving objects from API failed: " + msg);
				}
			});

			return p;
		}

		/** 
		* Get specific objects from several different models at once
		* 
		* As it's argument, it takes a StringMap, where each key represents the name of a model and
		* each value is an iterable of IDs for that model.  
		* 
		* Eg:
		*
		*  getMany([
		*  	"app.model.Farmer" => [33,34,35],
		*  	"app.model.Crop" => [1,2,5]
		*  ]);
		* 
		* A promise will be created for each requested object as well.
		*
		* This will make a fresh API call and overwrite and existing cached objects.
		* 
		* @param a map of the IDs to get, as explained above.
		* @return a promise for when all of the objects are fetched, containing a Map: "ModelName" => (id => object)
		* @throws (String) an error message, if ClientDs.api has not been set.
		* @reject (String) an error message if objects could not be retrieved from the server
		*/
		public static function getObjects(map:StringMap<Array<SUId>>):Promise<ClientDsResultSet>
		{
			if (api == null) throw "Please set static property 'api' before using ClientDs";

			var p = new Promise();

			// Make the API call
			api.get(map, function (result) {
				switch (result)
				{
					case Success(rs):

						// Process each and resolve individual promises
						processResultSet(rs);
						// Resolve the overall promise
						p.resolve(rs);

					case Failure(msg):
						p.reject("ClientDs, retrieving objects from API failed: " + msg);
				}
			});

			// Set up promises for each object
			for (modelName in map.keys())
			{
				var model = Type.resolveClass(modelName);
				var modelDS = getClientDsFor(model);
				
				for (id in map.get(modelName))
				{
					if (modelDS.ds.exists(id) == false)
					{
						modelDS.ds.set(id, new Promise());
					}
				}
			}

			return p;
		}

		/** 
		* Save many objects to the server at once.
		* 
		* Currently does not perform bulk SQL insert operations.  This will call save() on the server and so
		* insert() or update() the object.  All validation and permission checks still take place.
		* 
		* @param A StringMap, key=modelName, value=[array of objects to save]
		* @return A promise for the same map that was input, but the IDs were updated as they were saved.
		* @throws (String) an error message, if ClientDs.api has not been set.
		* @reject The promise is rejected if some objects failed to save.  The rejection throws an anonymous 
		*   object: { failed: [failed objects], saved: [successfully saved objects] }.  Any failures will also
		*   trace an error message for now.  I should come up with a better system though.
		*/
		public static function saveObjects(objectsToSave:Map<String, Array<ufcommon.db.Object>>):Promise<Map<String, Array<ufcommon.db.Object>>>
		{
			if (api == null) throw "Please set static property 'api' before using ClientDs";

			var p = new Promise();

			// Make the API call
			api.save(objectsToSave, function (result) {
				var failed = [];
				var saved = [];
				for (modelName in result.keys())
				{
					var originalArray = objectsToSave.get(modelName);
					var results:Array<Outcome<SUId, String>> = result.get(modelName);
					var i = 0;
					for (outcome in results)
					{
						var originalObject = originalArray[i];
						switch (outcome)
						{
							case Success(newID):
								originalObject.id = newID;
								saved.push(originalObject);
							case Failure(msg):
								trace("ClientDs, failed to save $originalObject: " + msg);
								failed.push(originalObject);
						}
						i++;
					}
				}
				if (failed.length == 0)
					p.resolve(objectsToSave);
				else
					p.reject({ saved: saved, failed: failed });
			});

			return p;
		}

		/** 
		* Delete the specified objects from the server
		* 
		* @param a StringMap, key=modelName, value=[array of objects]
		* @return A promise for the same map that was input
		* @throws (String) an error message, if ClientDs.api has not been set.
		* @reject The promise is rejected if some objects failed to dekete.  The rejection throws an anonymous 
		*   object: { failed: [failed objects], deleted: [successfully deleted objects] }.  Any failures will also
		*   trace an error message for now.  I should come up with a better system though.
		*/
		public static function deleteObjects(objectsToDelete:Map<String, Array<ufcommon.db.Object>>):Promise<Map<String, Array<ufcommon.db.Object>>>
		{
			if (api == null) throw "Please set static property 'api' before using ClientDs";

			var p = new Promise();

			// Change the map to use IDs, not the actual object
			var idsToDelete = new Map<String, Array<SUId>>();
			for (modelName in objectsToDelete.keys())
			{
				var idArr = objectsToDelete.get(modelName).map(function (obj) return obj.id);
				idsToDelete.set(modelName, idArr);
			}

			// Make the API call
			api.delete(idsToDelete, function (result) {
				var failed = [];
				var deleted = [];
				for (modelName in result.keys())
				{
					var originalArray = objectsToDelete.get(modelName);
					var results:Array<Outcome<SUId, String>> = result.get(modelName);
					var i = 0;
					for (outcome in results)
					{
						var originalObject = originalArray[i];
						switch (outcome)
						{
							case Success(_):
								deleted.push(originalObject);
							case Failure(msg):
								trace("ClientDs, failed to delete $originalObject: " + msg);
								failed.push(originalObject);
						}
						i++;
					}
				}
				if (failed.length == 0)
					p.resolve(objectsToDelete);
				else
					p.reject({ deleted: deleted, failed: failed });
			});

			return p;
		}

		//
		// Private members
		//

		static function processResultSet(rs:ClientDsResultSet):StringMap<IntMap<ufcommon.db.Object>>
		{
			var map = new StringMap<IntMap<ufcommon.db.Object>>();

			// For each model
			for (modelName in rs.keys())
			{
				// Find the DS
				var model = Type.resolveClass(modelName);
				var modelDS = getClientDsFor(model);

				// Set up the IntMap to return
				var intMap = new IntMap<ufcommon.db.Object>();
				map.set(modelName, intMap);

				// For each item
				var items = rs.get(modelName);
				for (item in items)
				{
					// Get the ID, add it to the return map
					var id = item.id;
					intMap.set(id, item);

					// Find the promise, or create it
					var p:Promise<Dynamic> = null;
					var newPromise = true;
					if (modelDS.ds.exists(id)) 
					{
						p = modelDS.ds.get(id);

						// If it exists, but hasn't been resolved, we'll use that promise
						if (Promise.allSet([p]) == false) newPromise = false;
					}
					if (newPromise) 
					{
						p = new Promise();
						modelDS.ds.set(id, p);
					}

					// Resolve it
					p.resolve(item);
				}
			}

			return map;
		}
	}
#end 