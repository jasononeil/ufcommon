package ufcommon.db;

#if server 
	import sys.db.Types;
#else 
	import ufcommon.db.Types;
#end

/** Extended Database Object

Builds on sys.db.Object, but adds: a default unique ID (unsigned Int), as well as created and modified timestamps.

Also has methods to keep the timestamps up to date, and a generic "save" method when you're not sure if you need to insert or update.

This class also uses conditional compilation so that the objects can exist on non-server targets that have no access to sys.db.*, on
these platforms the objects can be created and exist, but have no access to save(), insert(), update() or delete().  

We tell if it's a server platform by seeing checking for the #server define, so on your neko/php/cpp targets use `-D server`.
*/
#if server
	@noTable
	@:autoBuild(ufcommon.db.DBMacros.setupRelations())
#else
	@:keepSub
	@:rtti
	@:autoBuild(ufcommon.db.DBMacros.setupRelations())
#end 
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
		public function save()   { throw "Cannot save ufcommon.db.Object from the client."; } // Remoting call (or saves to local storage and wait for a sync()?) 
		public function delete() { throw "Cannot delete ufcommon.db.Object from the client."; } // Remoting call (or saves to local storage and wait for a sync()?) 
		public function insert() { throw "Cannot insert ufcommon.db.Object from the client."; } // Remoting call (or saves to local storage and wait for a sync()?)
		public function update() { throw "Cannot update ufcommon.db.Object from the client."; } // Remoting call (or saves to local storage and wait for a sync()?)
	
	#end
}

typedef BelongsTo<T> = T;
typedef HasMany<T> = Iterable<T>;