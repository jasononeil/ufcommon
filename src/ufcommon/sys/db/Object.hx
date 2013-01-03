package ufcommon.sys.db;


#if (neko || php || cpp)
	typedef Object = sys.db.Object;
#else 
	class Object implements haxe.rtti.Infos
	{
		public function new() {}
		
		// Currently not implemented, but we should...
		
		public function delete() { throw "Not implemented yet."; } // Remoting call (or saves to local storage and wait for a sync()?) 
		public function insert() { throw "Not implemented yet."; } // Remoting call (or saves to local storage and wait for a sync()?)
		public function update() { throw "Not implemented yet."; } // Remoting call (or saves to local storage and wait for a sync()?)
		
	}
#end