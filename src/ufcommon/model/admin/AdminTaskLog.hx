package ufcommon.model.admin;

import haxe.Json;
import ufcommon.db.Object;
#if server 
	import sys.db.Types;
#else 
	import ufcommon.db.Types;
#end

@:table("_admintasklog")
class AdminTaskLog extends Object
{
	public var ts:SString<255>;
	public var task:SString<255>;

	public var output:SText;

	public function new(ts:AdminTaskSet, task:String, output:String)
	{
		super();

		this.ts = ts.taskSetName;
		this.task = task;
		this.output = output;
	}

	public static var manager = new sys.db.Manager<AdminTaskLog>(AdminTaskLog);
}