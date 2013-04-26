package clientds;

import app.Api;
import ufcommon.remoting.*;
import ufcommon.db.Object;
using clientds.ClientDsResultSet;
using tink.core.types.Outcome;

#if client
	import ufcommon.db.Types;
	import clientds.Promise;
	import haxe.ds.*;
	using Lambda;

	class ClientDs<T:Object> #if !macro implements RequireApiProxy<ClientDsApi> #end
	{
		//
		// Factory
		//

		/** 
		* Get (or create) a ClientDS for the given model.  
		*
		* If you're using Object, this will be attached to your models on the client in the same way
		* that a manager is attached on the server, essentially:
		*
		*     static var clientDS:ClientDs<MyModel> = ClientDs.getClientDsFor(MyModel);
		* 
		* @param The model to get a client for
		* @return The ClientDS (DataStore) for that model
		*/
		public static function getClientDsFor<W:Object>(model:Class<W>):ClientDs<W>
		{
			if (stores == null) stores = new StringMap();
			
			var name = Type.getClassName(model);
			if (stores.exists(name))
			{
				return cast stores.get(name);
			}
			else 
			{
				var ds = new ClientDs(model);
				stores.set(name, cast ds);
				return ds;
			}
		}
		static var stores:StringMap<ClientDs<Object>>;

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
		var searchPromises:StringMap<Promise<IntMap<T>>>;

		/** Constructor is private.  Please use ClientDS.getClientDsFor(model) to create */
		function new(model:Class<T>)
		{
			this.model = model;
			this.modelName = Type.getClassName(model);
			this.ds = new IntMap();
			this.allPromise = null;
			this.searchPromises = new StringMap();
		}

		/** 
		* Fetch an object for the given ID.  
		*
		* @param The id of the object to get.
		* @return This returns a promise.  When the object is received (or if it's already cached), the promise
		*   will be fulfilled and your code will execute. If the object was not found, the promise will resolve as null.
		* @throws (String) an error message, if ClientDs.api has not been set.
		*/
		public function get(id:SUId):Promise<Null<T>>
		{
			if (api == null) throw "Please set static property 'api' before using ClientDs";
			
			if (ds.exists(id)) 
			{ 
				// If it already exists, return that promise.
				return ds.get(id); 
			}
			else 
			{
				// Else, create the promise
				var p = new Promise<T>();
				ds.set(id, p);
				
				if (allPromise == null)
				{
					// Otherwise, create a new call just to retrieve this object
					var req = new ClientDsRequest().get(cast model, id);
					processRequest(req);
				}
				// else 
					// If an existing call to all() has been made, wait for that
					// processRequest() will unpack the all and resolve our promise

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
		public function getMany(ids:Array<SUId>):Promise<IntMap<T>>
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
				var req = new ClientDsRequest().getMany(cast model, ids);
				processRequest(req);
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
		*/
		public function all():Promise<IntMap<T>>
		{
			if (allPromise == null)
			{
				if (api == null) throw "Please set static property 'api' before using ClientDs";
				
				allPromise = new Promise();

				// Make the API call
				var req = new ClientDsRequest().all(cast model);
				processRequest(req);
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
			var criteriaStr = haxe.Json.stringify(criteria);

			if (searchPromises.exists(criteriaStr))
			{
				// Do nothing, we'll just use the existing promise
				prom = searchPromises.get(criteriaStr);
			}
			else if (allPromise != null)
			{
				// Wait for the entire list to load, and then do a filter
				prom = new Promise();
				allPromise.then(function (intMap) {
					prom.resolve(cast ClientDsUtil.filterByCriteria(intMap, criteria));
				});
			}
			else
			{
				// No existing cache, so do a call to the API, which will do a dynamicSearch()
				if (api == null) throw "Please set static property 'api' before using ClientDs";
				
				prom = new Promise();
				searchPromises.set(criteriaStr, prom);

				// Make the API call
				var req = new ClientDsRequest().search(cast model, criteria);
				processRequest(req);
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
		* @return A promise that will be fulfilled when the API call is finished.  The promise is for a Result, if the save
		*   was a success, it will contain the same object.  The 'id' field will be updated if the object was freshly inserted.
		*   If the save was a failure, it will contain an error message.
		*/
		public function save(o:T):Promise<Outcome<T,String>>
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
						p.resolve(o.asSuccess());
					case Failure(msg):
						p.resolve('Failed to delete $o: $msg'.asFailure());
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
		* @return A promise containing the same ID if it was a Success, or an error message if it was a Failure.
		*/
		public function delete(id:SUId):Promise<Outcome<SUId,String>>
		{
			if (api == null) throw "Please set static property 'api' before using ClientDs";

			var p = new Promise();
			var map = [ modelName => [id] ];
			api.delete(map, function (result) {
				var outcome = result.get(modelName)[0];
				switch (outcome)
				{
					case Success(id):
						p.resolve(id.asSuccess());
					case Failure(msg):
						p.resolve('Failed to delete $modelName[$id]: $msg'.asFailure());
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
			var criteriaStr = haxe.Json.stringify(criteria);
			searchPromises.remove(criteriaStr);
			return search(criteria);
		}

		//
		// Static methods
		//

		/**
		* Process a CleintDsRequest object and return the results. Will call ClientDsApi.get()
		*
		* Your request will force a reload of any objects it finds.  If you want to check for a cached version, use
		* the model's ClientDs.
		*
		* @param req - the ClientDsRequest you wish to get results for.
		* @throws (String) an error message, if ClientDs.api has not been set.
		* @return A promise for the result set.  Is actually an Outcome, with Success containing the ClientDsResultSet,
		*   and Failure containing the error message (String).
		*/
		public static function processRequest(req:ClientDsRequest):Promise<Outcome<StringMap<IntMap<Object>>, String>> 
		{
			if (api == null) throw "Please set static property 'api' before using ClientDs";

			var resultSetPromise = new Promise();

			// Create promises for each bit of the request
			for (modelName in req.requests.keys())
			{
				var r = req.requests.get(modelName);
				var clientDs = getClientDsFor(Type.resolveClass(modelName));

				// If an all was requested, create/recreate the promise for it
				if (r.all)
				{
					if (clientDs.allPromise == null || Promise.allSet([clientDs.allPromise]))
						clientDs.allPromise	= new Promise();
				}

				// Create / recreate promises for any search requests
				for (s in r.search)
				{
					var criteriaStr = haxe.Json.stringify(s.c);
					var p = clientDs.searchPromises.get(criteriaStr);
					if (p == null || Promise.allSet([p]))
						clientDs.searchPromises.set(criteriaStr, new Promise());
				}
				
				// Create / recreate promises for any get requests
				for (g in r.get)
				{
					var p = clientDs.ds.get(g.id);
					if (p == null || Promise.allSet([p]))
						clientDs.ds.set(g.id, new Promise());
				}

				// Create / recreate promises for any getMany requests
				// We don't create a separate promise for the getMany request itself.
				// If myClientDs.getMany() is called, it will check against the individual
				// ids, rather than against them as a set. So we only need to track individuals.
				for (g in r.getMany)
				{
					for (id in g.ids)
					{
						var p = clientDs.ds.get(id);
						if (p == null || Promise.allSet([p]))
							clientDs.ds.set(id, new Promise());
					}
				}
			}
			
			// Process the request, resolve the response outcome
			api.get(req, function (results) {
				switch(results)
				{
					case Success(rs): 
						var map = processResultSet(req, rs);
						resultSetPromise.resolve(map.asSuccess());
					case Failure(error): 
						resultSetPromise.resolve(error.asFailure());
				}
			});
			return resultSetPromise;
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
		*   object: { failed: [ { o:failedObject, err:errorMessage }], saved: [successfully saved objects] }.  Any failures will also
		*   trace an error message for now.  I should come up with a better system though.
		*/
		public static function saveObjects(objectsToSave:Map<String, Array<Object>>):Promise<Map<String, Array<Object>>>
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
								failed.push({ o:originalObject, err:msg });
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
		* @param a StringMap, key=modelName, value=[array of objects to delete]
		* @return A promise for the same map that was input
		* @throws (String) an error message, if ClientDs.api has not been set.
		* @reject The promise is rejected if some objects failed to dekete.  The rejection throws an anonymous 
		*   object: { failed: [failed objects], deleted: [successfully deleted objects] }.  Any failures will also
		*   trace an error message for now.  I should come up with a better system though.
		*/
		public static function deleteObjects(objectsToDelete:Map<String, Array<Object>>):Promise<Map<String, Array<Object>>>
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

		public static macro function when(args:Array<ExprOf<Promise<Dynamic>>>):Expr
		{
			// just using a simple pos for all expressions
			var pos = args[0].pos;
			// Dynamic Complex Type expression
			var d = TPType("Dynamic".asComplexType());
			// Generic Dynamic Complex Type expression
			var p = "promhx.Promise".asComplexType([d]);
			var ip = "Iterable".asComplexType([TPType(p)]);
			//The unknown type for the then function, also used for the promise return
			var ctmono = Context.typeof(macro null).toComplex(true);
			var eargs:Expr; // the array of promises
			var ecall:Expr; // the function call on the promises


			// multiple argument, with iterable first argument... treat as error for now
			if (args.length > 1 && ExprTools.is(args[0],ip)){
				Context.error("Only a single Iterable of Promises can be passed", args[1].pos);
			} else if (ExprTools.is(args[0],ip)){ // Iterable first argument, single argument
				var cptypes =[Context.typeof(args[0]).toComplex(true)];
				eargs = args[0];
				ecall = macro {
					var arr = [];
					for (a in $eargs) arr.push(a._val);
					f(arr);
				}
			} else { // multiple argument of non-iterables
				for (a in args){
					if (ExprTools.is(a,p)){
						//the types of all the arguments (should be all Promises)
						var types = args.map(Context.typeof);
						//the parameters of the Promise types
						var ptypes = types.map(function(x) switch(x){
							case TInst(_,params): return params[0];
							default : {
								Context.error("Somehow, an illegal promise value was passed",pos);
								return null;
							}
						});
						var cptypes = ptypes.map(function(x) return x.toComplex(true)).array();
						//the macro arguments expressed as an array expression.
						eargs = {expr:EArrayDecl(args),pos:pos};

						// An array of promise values
						var epargs = args.map(function(x) {
							return {expr:EField(x,"_val"),pos:pos}
						}).array();
						ecall = {expr:ECall(macro f, epargs), pos:pos}
					} else{
						Context.error("Arguments must all be Promise types, or a single Iterable of Promise types",a.pos);
					}
				}
			}

			// the returned function that actually does the runtime work.
			return macro {
				var parr:Array<Promise<Dynamic>> = $eargs;
				var p = new Promise<$ctmono>();
				{
					then : function(f){
						 //"then" function callback for each promise
						var cthen = function(v:Dynamic){
							if ( Promise.allSet(parr)){
								try{ 
									if ( Promise.allSet([p]) == false )
										untyped p.resolve($ecall); 
								}
								catch(e:Dynamic){
									untyped p.handleError(e);
								}
							}
						}
						if (Promise.allSet(parr)) cthen(null);
						else for (p in parr) p.then(cthen);
						return p;
					}
				}
			}
		}

		/**
		* This is basically the same as Promise.when(), but without the macro magic
		* (The macro magic was conflicting with one of the API building macros used here)
		*
		* The key differences:
		*  - Pass your promises in as an array, not a string of constants...
		*  - The arguments are figured out using untyped, and called using Reflect.callMethod()
		*  - So compile time checking is minimal.  Yeah, we should really fix this.
		*/
		public static function whenRuntime(promises:Array<Promise<Dynamic>>)
		{
			var p = new Promise<Dynamic>();
			return {
				then : function(f){
					if (Type.enumEq(Type.typeof(f), TFunction))
					{
						 //"then" function callback for each promise
						var cthen = function(v:Dynamic){
							if ( Promise.allSet(promises))
							{
								try
								{ 
									if ( Promise.allSet([p]) == false )
									{
										var args = promises.map(function (p) return untyped p._val);
										var result = Reflect.callMethod({}, f, args);
										untyped p.resolve(result); 
									}
								}
								catch(e:Dynamic)
								{
									untyped p.handleError(e);
								}
							}
						}
						if (Promise.allSet(promises)) cthen(null);
						else for (p in promises) p.then(cthen);
					}
					else throw "Invalid function parsed to when()";
					return p;
				}
			}
		}

		//
		// Private members
		//


		static function processResultSet(req:ClientDsRequest, rs:ClientDsResultSet):StringMap<IntMap<Object>>
		{
			var map = new StringMap<IntMap<Object>>();

			var promisesToResolve:Array<Promise<Dynamic>> = [];

			// Add all of the items in each model, resolve item promises
			for (model in rs.models())
			{
				// Find the DS
				var modelDS = getClientDsFor(model);
				var modelName = Type.getClassName(model);

				// Set up the IntMap to return
				var items = rs.items(model);
				map.set(modelName, items);

				// Resolve the individual promises
				for (item in items)
				{
					// Get the ID, add it to the return map
					var id = item.id;

					// Find the promise, or create it
					var p:Promise<Dynamic> = modelDS.ds.get(id);
					if (p == null || Promise.allSet([p]))
					{
						modelDS.ds.set(id, p = new Promise());
					}

					// Set the promise value
					PromiseAbuse.setWithoutFiring(p, item);
					promisesToResolve.push(p);
				}

				// Resolve the all promise
				if (rs.hasAllRequest(modelName))
				{
					// Create / Recreate the promise if needed
					if (modelDS.allPromise == null || Promise.allSet([modelDS.allPromise]))
						modelDS.allPromise	= new Promise();
					
					// Set the promise value
					PromiseAbuse.setWithoutFiring(modelDS.allPromise, rs.items(model));
					promisesToResolve.push(modelDS.allPromise);
				}

				// Resolve the search promises
				for (criteria in rs.searches(model))
				{
					// Get, create or recreate the search promise
					var criteriaStr = haxe.Json.stringify(criteria);
					var p = modelDS.searchPromises.get(criteriaStr);
					if (p == null || Promise.allSet([p]))
						modelDS.searchPromises.set(criteriaStr, new Promise());
					
					// Set the promise value
					var results = rs.searchResults(model,criteria);
					if (results != null) 
					{
						PromiseAbuse.setWithoutFiring(p, results);
						promisesToResolve.push(p);
					}
				}
			}

			// See notes in PromiseAbuse.hx for why we've split setting/firing
			// But here, we've set all of our promises, now fire the handlers
			for (p in promisesToResolve)
			{
				try 
				{
					PromiseAbuse.fireWithoutSetting(p);	
				}
				catch (e:String)
				{
					if (e == "Promise has already been resolved")
					{
						trace ("That promise resolved twice...");
						// When does this happen?
						// var combinedProm = Promise.when(p1,p2);
							// p1.then( /* If p1 and p2 set, resolve combindedProm */ )
							// p2.then( /* If p1 and p2 set, resolve combindedProm */ )
						// PromiseAbuse.setWithoutFiring(p1, val1);
						// PromiseAbuse.setWithoutFiring(p2, val2);
						// PromiseAbuse.fireWithoutSetting(p1);
							// p1.then() ... p1 and p2 set ... resolve combinedProm
						// PromiseAbuse.fireWithoutSetting(p2);
							// p2.then() ... p1 and p2 set ... resolve combinedProm
							// Uh oh! Resolved twice...
							// I knew this was a bad idea.  try {} catch {} for now.
					}
					else throw e;
				}
			}

			return map;
		}

	}
#end 