package ufcommon.db;

import ufcommon.db.Types;
import ufcommon.db.Object;
#if server 
	import sys.db.Manager;
#end 

class Relationship extends Object
{
	public var r1:SInt;
	public var r2:SInt;
	
	public function new(r1:Int, r2:Int)
	{
		super();
		this.r1 = r1;
		this.r2 = r2;
	}
}
