package ufcommon.db;

import ufcommon.db.Types;

#if (neko || php || cpp)
	class Object extends sys.db.Object
	{
		public var id:SId;
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
	}
#else 
	class Object implements haxe.rtti.Infos
	{
		public var id:SId;
		public var created:SDateTime;
		public var modified:SDateTime;

		public function new() {}
		
		// Currently not implemented, but we should...
		
		public function delete() { throw "Not implemented yet."; } // Remoting call (or saves to local storage and wait for a sync()?) 
		public function insert() { throw "Not implemented yet."; } // Remoting call (or saves to local storage and wait for a sync()?)
		public function update() { throw "Not implemented yet."; } // Remoting call (or saves to local storage and wait for a sync()?)
		
	}
#end