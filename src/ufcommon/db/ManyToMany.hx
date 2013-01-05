package ufcommon.db;

import ufcommon.db.Types;
import ufcommon.db.Object;
import ufcommon.db.Relationship;
import sys.db.Manager;

// Note:
// Throughout this class, I've had to replace SPOD macro calls with the "unsafe" runtime calls.
// The reason for this is that the macro versions hardcode the table name into the query - and so
// they always use the "Relationship" table, rather than our custom table names for each join.
// In the code, I've left the macro line above the "unsafe" line, but commented out, so that 
// you can see essentially what it is that we're trying to do.

class ManyToMany<A:Object, B:Object>
{
	static var managers:Hash<Manager<Object>> = new Hash();
	
	var a:Class<A>;
	var b:Class<B>;
	var aObject:A;
	var bManager:Manager<app.coredata.model.Department>;
	var tableName:String;
	var manager:Manager<Relationship>;
	var bList:List<B>;
	
	public function new(aObject:A, bClass:Class<B>)
	{
		this.a = Type.getClass(aObject);
		this.b = bClass;
		this.aObject = aObject;
		// bManager = untyped b.manager;
		bManager = app.coredata.model.Department.manager;
		this.tableName = generateTableName();

		if (managers.exists(tableName))
		{
			// Managers are stored as Manager<Object>, we want to cast it to Manager<Relationship<A,B>>
			this.manager = cast managers.get(tableName);
		}
		else 
		{
			this.manager = new Manager(Relationship);
			setTableName(tableName);
			managers.set(tableName, cast manager);
		}

		refreshList();
	}
		
	function generateTableName()
	{
		// Get the names (class name, last section after package list, lower case)
		var aName = Type.getClassName(a).split('.').pop();
		var bName = Type.getClassName(b).split('.').pop();

		// Sort the names alphabetically, so we don't end up with 2 join tables...
		var arr = [a,b];
		arr.sort(function(x,y) return Reflect.compare(x,y));

		// Join the names - eg join_SchoolClass_Student
		arr.unshift("join");
		return arr.join('_');
	}

	@:access(sys.db.Manager)
	function setTableName(name:String)
	{
		manager.table_name = name;
	}
		
	@:access(sys.db.Manager)
	public function refreshList()
	{
		var id = aObject.id;
		// var relationships = manager.search($a == id);
		var relationships = manager.unsafeObjects("SELECT * FROM " + Manager.quoteAny(tableName) + " WHERE a = " + Manager.quoteAny(id), false);
		var bListIDs = relationships.map(function (r:Relationship) { return r.b; });
		
		// Search B table for our list of IDs.  
		// bList = bManager.search($id in bListIDs);
		var xlist = bManager.unsafeObjects("SELECT * FROM " + Manager.quoteAny(bManager.table_name) + " WHERE " + Manager.quoteList("id", bListIDs), false);
	}
		
	public function add(bObject:B)
	{
		bList.add(bObject);

		if (bObject.id == null)
			bObject.insert();
		else
			bObject.update();
		
		var r = new Relationship(aObject.id, bObject.id);
		r.insert();
	}

	public function remove(bObject:B)
	{
		bList.remove(bObject);
		// manager.delete($a == aObject.id && $b == bObject.id);
		manager.unsafeDelete("DELETE FROM " + Manager.quoteAny(tableName) + " WHERE a = " + Manager.quoteAny(aObject.id) + " AND b = " + Manager.quoteAny(bObject.id));
	}

	public function clear()
	{
		bList.clear();
		// manager.delete($a == aObject.id);
		manager.unsafeDelete("DELETE FROM " + Manager.quoteAny(tableName) + " WHERE a = " + Manager.quoteAny(aObject.id));
	}

	public function iterator():Iterator<B>
	{
		return bList.iterator();
	}

	public function pop():B
	{
		var bObject = bList.pop();
		// manager.delete($a == aObject.id && $b == bObject.id);
		manager.unsafeDelete("DELETE FROM " + Manager.quoteAny(tableName) + " WHERE a = " + Manager.quoteAny(aObject.id) + " AND b = " + Manager.quoteAny(bObject.id));
		return bObject;
	}

	public function push(bObject:B)
	{
		bList.push(bObject);
		if (bObject.id == null)
			bObject.insert();
		else
			bObject.update();
		
		var r = new Relationship(aObject.id, bObject.id);
		r.insert();	
	}
}


