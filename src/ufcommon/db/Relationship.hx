package ufcommon.db;

import ufcommon.db.Object; 
#if server 
	import sys.db.Manager;
	import sys.db.Types;
#else 
	import ufcommon.db.Types;
#end

@noTable
class Relationship extends Object
{
	public var r1:SUInt;
	public var r2:SUInt;
	
	public function new(r1:Int, r2:Int)
	{
		super();
		this.r1 = r1;
		this.r2 = r2;
	}
}
