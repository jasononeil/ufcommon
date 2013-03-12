package ufcommon.db;

#if server 
	import sys.db.Types;
#else 
	import ufcommon.db.Types;
#end

#if server
	@noTable
	@:autoBuild(ufcommon.db.DBMacros.setupRelations())
	class Object extends sys.db.Object
	{
		public var id:SUId;
		public var created:SDateTime;
		public var modified:SDateTime;

		override public function insert()
		{
			this.created = Date.now();
			this.modified = Date.now();
			super.insert();
		}

		override public function update()
		{
			this.modified = Date.now();
			super.update();
		}
		
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
	}
#else 
	@:keepSub
	@:rtti
	@:autoBuild(ufcommon.db.DBMacros.setupRelations())
	class Object
	{
		public var id:SId;
		public var created:SDateTime;
		public var modified:SDateTime;

		public function new() {}
		
		// Currently not implemented, but we should...
		
		public function save()   { throw "Not implemented yet."; } // Remoting call (or saves to local storage and wait for a sync()?) 
		public function delete() { throw "Not implemented yet."; } // Remoting call (or saves to local storage and wait for a sync()?) 
		public function insert() { throw "Not implemented yet."; } // Remoting call (or saves to local storage and wait for a sync()?)
		public function update() { throw "Not implemented yet."; } // Remoting call (or saves to local storage and wait for a sync()?)
		
	}
#end

typedef BelongsTo<T> = T;
typedef HasMany<T> = Iterable<T>;