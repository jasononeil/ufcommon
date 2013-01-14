Models
======

 * Models are to be generic across targets and function as self standing objects that can be understood on client or server
 * Only server contains the manager to directly interact with the database
 * If the client wants to interact with the database, it must do it via the API
 * The client can cache a copy of an object for offline access.  The offline cache is a "dumb" store, with no access to the API, and simple read(id):T write(T):id access
 
Sample for reading a list of users

 * Create an API -> UserAPI.getAllUsers():List<User>;
 	* Checks that the person has appropriate authentication
 	* Gets list with User.manager.all();
 	* Ensures sensitive data is removed etc
 * Server controller can access the API directly, output list as ViewResult
 * Client controller can remotely access the API, insert list into View

Sample for reading a form and saving it to the database

 * Create an API -> UserAPI.save(u:User):Result;
 	* Checks that the person is allowed to do this
 	* Checks that the data is valid
 	* Inserts it with u.save();
 	* Returns a Result
 * Server
 	* Display Form
 	* If (post)
 		* user = readPostData()
 		* UserAPI.save(user)
 		* if (valid) successView
 		* if (failure) -> validation -> Display form with errors
 		               -> other -> Display error message
 * Client
 	* Display Form
 	* on(submit)
 		* user = readForm()
 		* validate on client, show errors if need be
 		* userAPI.save(user);
 		* if (valid) successView
 		* if (failure) -> display error message

### Offline but API if online

Offline workflow example (showing list)

 * API UserAPI.getAllUsers():List<User>;
 * Client
 	* If online
 		* userAPI.getAllUsers()
 		* users -> view -> display
 		* add each to cache
 	* If offline
 		* OfflineUserCache.all();
 		* users -> view -> display
 		Also:
 		* OfflineUserCache.get(13);
 		* OfflineUserCache.get(allMyUsers:Iterable<SId>);

Offline workflow example (saving)

 * API UserAPI.save()
 * Client
 	* If online
 		* Form, read form, validate, API, show result
 	* If offline
 		* Form, read form
 		* Validate, show errors if failure
 		* Save to OfflineUserStore.set(s)
 		* Save to OfflineSyncList(User, id)
 	* When online
 		* Sync everything in sync list

Offline is the bomb, but sync using API

 * API UserAPI.getAllUsers():List<User>;
 * Client
 	* To read list:
 		* OfflineUserCache.all();
 		* OfflineUserCache.get(allMyUsers:Iterable<SId>);
 		* users -> view -> display
  	* To view individual
 		* OfflineUserCache.get(13);
 		* user -> view -> display
 	* To save
 		* Display form, read form
 		* Validate, show errors if failure
 		* Save to OfflineUserStore.set(s)
 		* Save to OfflineSyncList(User, id)
 	* When online, periodically (or on request) run sync()
 		* Get new rows since (lastSyncDate)
 		* Send rows in sync list


For this to work, a model needs to:

 * Validation is in the model so it can be performed on the client
 * Model properties can be used online/offline easily
 * Model relationships need to be stored in a simple iterable that can be serialised and sent to / stored on the client...
 * Any logic in models that requires the manager (eg. to populate relationships) needs to be in #if server ... #end