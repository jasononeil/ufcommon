package ufcommon.db;

import ufcommon.db.Types;
import ufcommon.db.Object;
#if server 
	import sys.db.Manager;
#end 

class Relationship extends Object
{
	public var a:SInt;
	public var b:SInt;
	
	public function new(a:Int, b:Int)
	{
		super();
		this.a = a;
		this.b = b;
	}
}