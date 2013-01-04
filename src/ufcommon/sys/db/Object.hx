package ufcommon.sys.db;

import ufcommon.sys.db.Types;

#if (neko || php || cpp)
	class Object extends sys.db.Object
	{
		public var id:SId;
	}
#else 
	class Object implements haxe.rtti.Infos
	{
		public var id:SId;

		public function new() {}
		
		// Currently not implemented, but we should...
		
		public function delete() { throw "Not implemented yet."; } // Remoting call (or saves to local storage and wait for a sync()?) 
		public function insert() { throw "Not implemented yet."; } // Remoting call (or saves to local storage and wait for a sync()?)
		public function update() { throw "Not implemented yet."; } // Remoting call (or saves to local storage and wait for a sync()?)
		
	}
#end