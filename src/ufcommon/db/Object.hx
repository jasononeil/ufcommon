package ufcommon.db;

import sys.db.Types;

/** Extended Database Object

Builds on sys.db.Object, but adds: a default unique ID (unsigned Int), as well as created and modified timestamps.

Also has methods to keep the timestamps up to date, and a generic "save" method when you're not sure if you need to insert or update.

This class also uses conditional compilation so that the objects can exist on non-server targets that have no 
access to sys.db.*, on these platforms the objects can be created and shared with remoting, and will be able to
save and fetch records through ClientDS.

We tell if it's a server platform by seeing checking for the #server define, so on your neko/php/cpp targets use `-D server`.

Two build macros will be applied to all objects that extends this class:

 * The first, is used to detects HasMany<T>, BelongsTo<T> and ManyToMany<A,B> types and 
sets them up as properties so they are handled correctly.
 * The second adds a "manager:sys.db.Manager" property on the server, or a "clientDS:clientds.ClientDs" property on the
 client, and initialises them.

*/
#if server
	@noTable
#else
	@:keepSub
	@:rtti
#end 
@:autoBuild(ufcommon.db.DBMacros.setupRelations())
@:autoBuild(ufcommon.db.DBMacros.addManager())
class Object #if server extends sys.db.Object #end
{
	public var id:SUId;
	public var created:SDateTime;
	public var modified:SDateTime;

	#if server

		/** Updates the "created" and "modified" timestamps, and then saves to the database. */
		override public function insert()
		{
			this.created = Date.now();
			this.modified = Date.now();
			super.insert();
		}

		/** Updates the "modified" timestamp, and then saves to the database. */
		override public function update()
		{
			this.modified = Date.now();
			super.update();
		}
		
		/** Either updates or inserts the given record into the database, updating timestamps as necessary. 

		If `id` is null, then it needs to be inserted.  If `id` already exists, try to update first.  If that
		throws an error, it means that it is not inserted yet, so then insert it. */
		public function save()
		{
			if (id == null)
			{
				insert();
			}
			else
			{
				try 
				{
					untyped this._lock = true;
					update();
				}
				catch (e:Dynamic)
				{
					// It had an ID, but it wasn't in the DB... so insert it
					insert();
				}
			}
		}
	
	#else

		// Empty versions of these functions for the client.
		public function new() {}
		public function save()   { 
			throw "Cannot save ufcommon.db.Object from the client."; 
		}
		public function delete() { 
			throw "Cannot delete ufcommon.db.Object from the client."; 
		}
		public function insert() { 
			throw "Cannot insert ufcommon.db.Object from the client."; 
		}
		public function update() { 
			throw "Cannot update ufcommon.db.Object from the client."; 
		}
	
	#end
}

/** BelongsTo relation 

You can use this as if the field is just typed as whatever T is, but the build macro here will set it up as a property and will link to the related object correctly.  

T must be a type that extends ufcommon.db.Object  */
typedef BelongsTo<T> = T;

/** HasMany relation 

This type is transformed into a property that lets you iterate over related objects.  Related objects are determined by a corresponding "BelongsTo<T>" in the related class.  The returned list is read only - to update it you must update the related property on each object.

T must be a type that extends ufcommon.db.Object */
typedef HasMany<T> = Iterable<T>;

/** Shortcut to ManyToMany relation */
// typedef ManyToMany<A,B> = ufcommon.db.ManyToMany<A,B>;