package clientds;

import app.Api;
import ufcommon.remoting.*;
using tink.core.types.Outcome;

#if client
	import ufcommon.db.Types;
	import promhx.Promise;
	import haxe.ds.IntMap;
	using Lambda;

	class ClientDs<T:ufcommon.db.Object> implements RequireApiProxy<ClientDsApi>
	{
		public static var api:clientds.ClientDsApiProxy;

		var model:Class<T>;
		var modelName:String;
		var ds:IntMap<Promise<T>>;

		/** Create a new ClientDS for the given model.  It's a good idea to attach this to the model, like you would attach a manager on the server. */
		public function new(model:Class<T>)
		{

			this.model = model;
			this.modelName = Type.getClassName(model);
			this.ds = new IntMap();
		}

		/** Fetch an object for the given ID.  This returns a promise.  When the object is received (or if it's already cached), the promise
		will be fulfilled and your code will execute. */
		public function get(id:SUId):Promise<T>
		{
			if (api == null) throw "Please set static property 'api' before using ClientDs";
			
			// If it already exists, return that promise.
			if (ds.exists(id)) { trace ('Found cache for $modelName[$id]'); return ds.get(id); }

			// Else, create the promise
			var p = new Promise<T>();
			ds.set(id, p);

			// Set up the API call to resolve the promise.
			trace ('Begin retrieval of $modelName[$id]');
			api.get(modelName, id, function (result) {
				switch (result)
				{
					case Success(obj):
						trace ('Retrieved $modelName[$id] successfully');
						p.resolve(obj);
					case Failure(msg):
						trace ("ClientDs, retrieving object from API failed: " + msg);
				}
			});

			return p;
		}

		/** Fetch a bunch of objects given a bunch of IDs.  Eg clientDS.getMany([1,2,3,4]);  The promise returned is for an iterable
		containing all of the matched objects - so it will only fire when every requested object is available.  

		An individual promise will be placed in the cache for each object, so future requests for that individual object will be cached.

		This will try to be clever and not request objects that are already in the cache or being processed. */
		public function getMany(ids:Iterable<SUId>)
		{
			if (api == null) throw "Please set static property 'api' before using ClientDs";
			
			var newRequests = ids.filter(function (id) return ds.exists(id) == false);
			var existingPromises = ids.filter(function (id) return ds.exists(id) == false);
			var unfulfilledPromises = ids.array();
			var list = new IntMap();

			// Create a promise for the overall list
			var listProm = new Promise<IntMap<T>>();

			// Create a promise for each of the new requests
			for (id in newRequests)
			{
				ds.set(id, new Promise());
			}

			// As the existing promises are fulfilled, tick them off
			for (id in ids)
			{
				if (ds.exists(id))
				{
					var p = ds.get(id);
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
			}

			// Set up the API call to resolve the remainder
			//!!!!
			//!!!!
			//!!!!
			//!!!!

			// Return the promise while we wait for everything to resolve.
			return listProm;
		}

		/** Fetch all the objects belonging to a given model.  If some of the objects are already in the cache, they will be reloaded. */
		public function all()
		{
			if (api == null) throw "Please set static property 'api' before using ClientDs";
			
			// Set up the promise for the overall list
			var listProm = new Promise<IntMap<T>>();
			var list = new IntMap<T>();

			// Make the API call
			//!!!!
			//!!!!
			//!!!!
			//!!!!
				// processSelectResults(apiList, listProm)

			return listProm;
		}

		/** Fetch all the objects belonging that match the serach criteria. Same as Manager.dynamicSearch()  If some of the objects are already in the cache, they will be reloaded. */
		public function search(criteria:{})
		{
			if (api == null) throw "Please set static property 'api' before using ClientDs";
			
			// Set up the promise for the overall list
			var listProm = new Promise<IntMap<T>>();
			var list = new IntMap<T>();

			// Make the API call
			//!!!!
			//!!!!
			//!!!!
			//!!!!
				// processSelectResults(apiList, listProm)

			return listProm;
		}

		function processSelectResults(list:Iterable<T>, prom:Promise<IntMap<T>>)
		{
			var list = new IntMap<T>();

			for (obj in list)
			{
				// Set up promises for each item, so they're in the cache
				var p = new Promise();
				ds.set(obj.id, p);
				p.resolve(obj);

				// Add each item to our list
				list.set(obj.id, obj);
			}

			// Resolve our list promise
			prom.resolve(list);
		}
	}
#end 