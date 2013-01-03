package ufcommon.sys.db;

import ufcommon.sys.Types;
import ufcommon.sys.Manager;

class ManyToMany<A, B>
{
	static var managers:Hash<Manager> = new Hash();
	
	var a:Class<A>;
	var b:Class<B>;
	var tableName:String;
	var manager:Manager;
	var aObject:A;
	var bManager:Manager;
	var bList:List<B>;
	
	public function new(aObject:A, bClass:Class<B>)
	{
		a = Type.getClass(aObject);
		b = bClass;

		tableName = generateTableName(a,b);
		if (managers.exists(tableName))
		{
			manager = managers.get(tableName);
		}
		else 
		{
			manager = new Manager<A,B>(a,b,tableName);
			managers.set(tableName, manager);
		}

		this.aObject = aObject;
		bManager = b.manager;
		refreshList();
	}
		
	function generateTableName(a, b)
	{
		// Get the names (class name, last section after package list, lower case)
		var aName = if( a.TABLE_NAME != null ) a.TABLE_NAME else a.__name__[a.__name__.length-1];
		var bName = if( b.TABLE_NAME != null ) b.TABLE_NAME else b.__name__[b.__name__.length-1];

		// Sort the names alphabetically, so we don't end up with 2 join tables...
		var arr = [a,b].sort(function(x,y) return Reflect.compare(x,y));

		// Join the names - eg SchoolClass_join_Student
		return arr.join('_join_');
	}
		
	public function refreshList()
	{
		var relationships = manager.search($a == aObject);
		var bListIDs = relationships.map<Int>(function (r:Relationship) { return r.b; });
		bList = bManager.search($id in bListIDs);
	}
		
	public function add(bObject:B)
	{
		bList.add(o);
		bObject.update(); // check if it's changed?
		var r = new Relationship(aObject.id, bObject.id);
		r.insert();
	}

	public function remove(bObject:B)
	{
		bList.remove(bObject);
		r.delete($a == aObject.id && $b == bObject.id);
	}

	public function empty()
	{
		bList.empty();
		r.delete($a == aObject.id);
	}

	public function iterator():Iterator<B>
	{
		return bList.iterator();
	}

	public function pop():B
	{
		var bObject = bList.pop();
		r.delete($a == aObject.id && $b == bObject.id);
		return bObject;
	}

	public function push(bObject:B)
	{
		bList.push(o);
		bObject.update(); // check if it's changed?
		var r = new Relationship(aObject.id, bObject.id);
		r.insert();	
	}
}

class Relationship<A,B> extends sys.db.Object
{
	var id:SId;
	var a:SInt;
	var b:SInt;
	
	public function new(a:A, b:B)
	{
		this.a = a.id;
		this.b = b.id;
	}
}
