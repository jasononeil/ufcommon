Server/Client Controllers
=========================

The current path for online controllers:

 * Data is gathered via GET and POST and route information.
 * Gets route data, figures out correct action
 * Controller executes action
 	* Executes action
	 	* Calls API
	 		* Checks Auth
	 		* Interacts with database
	 		* Returns result
	 	* Result -> View
	 	* View -> Output
 * Controller provides callbacks

The plan for client:

 * Client data is gathered from a form or from clicks etc
 * Pushstate gets route data, figures out correct action
 * OR - a client action is requested directly
 * Controller executes action	
 	* Calls API (async)
 		* Checks Auth
 		* Interacts with database
 		* Returns result
 	* Result -> View
 	* View -> Output

For a first step, keep as much logic as possible in the API and in actions, and keep the views using the same technology so that unifying them later will be easier.

The eventual plan could look like:

 * Gets route data, figures out correct action (1)
 * Controller executes action (2)
 	* Executes action (3)
	 	* Calls API
	 		* Checks Auth
	 		* Interacts with database
	 		* Returns result
	 	* Result -> View
	 	* View -> Output (4)
 * Controller provides callbacks

Notes

1. Ufront routing on server, Pushstate on client, but draw the routing info from the controllers.

   It will be useful to have a way for pushstate to emulate post() and get()

2. The controllers become unified under UFronts BaseController... any server specific stuff is translated for the client

3. Action is executed async on client, but sync on server.  Can we use some macro magic to make the code look the same?  
   
   The easiest would be to have the code flow straight through, but on the client the API calls are picked up by a macro 
   and turned into callbacks, similar to how async() haxelibs are working.

   Another option would be to do async style on the client and the server, but the server calls are wrapped in such a way
   that they're actually synchronous.

4. Get the client ViewResult() to behave in a similar way to ufront... or align them somehow, so the action can just return 
   a view and know that it will display correctly.