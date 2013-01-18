package ufcommon.db;

#if server 
	import sys.db.Manager;
	import sys.db.Types;
#else 
	import ufcommon.db.Types;
#end
import ufcommon.db.Object;
import ufcommon.db.Relationship; 
using Lambda;

// Note:
// Throughout this class, I've had to replace SPOD macro calls with the "unsafe" runtime calls.
// The reason for this is that the macro versions hardcode the table name into the query - and so
// they always use the "Relationship" table, rather than our custom table names for each join.
// In the code, I've left the macro line above the "unsafe" line, but commented out, so that 
// you can see essentially what it is that we're trying to do.

// Note 2:
// On the server side, this class does all the expected database interactions.  On the client side
// it really does little more than keep a list of <B> objects.  When we send the ManyToMany object
// back to the server, it should then read the list, and sync it all up.

class ManyToMany<A:Object, B:Object>
{
	
	var a:Class<A>;
	var b:Class<B>;
	var aObject:A;
	var bList:List<B>;
	
	#if server 
		var tableName:String;
		static var managers:Hash<Manager<Object>> = new Hash();
		var bManager:Manager<B>;
		var manager:Manager<Relationship>;
	#end

	public function new(aObject:A, bClass:Class<B>)
	{

		#if server 
			this.a = Type.getClass(aObject);
			this.b = bClass;
			this.aObject = aObject;
			bManager = untyped b.manager;
			this.tableName = generateTableName(a,b);

			if (managers.exists(tableName))
			{
				// Managers are stored as Manager<Object>, we want to cast it to Manager<Relationship>
				this.manager = cast managers.get(tableName);
			}
			else 
			{
				this.manager = new Manager(Relationship);
				setTableName(tableName);
				managers.set(tableName, cast manager);
			}

			refreshList();
		#end 
	}
	
	function isABeforeB()
	{
		// Get the names (class name, last section after package list, lower case)
		var aName = Type.getClassName(a).split('.').pop();
		var bName = Type.getClassName(b).split('.').pop();
		var arr = [a,b];
		arr.sort(function(x,y) return Reflect.compare(x,y));
		return (arr[0] == a);
	}
		
	static public function generateTableName(a:Class<Dynamic>, b:Class<Dynamic>)
	{
		// Get the names (class name, last section after package list, lower case)
		var aName = Type.getClassName(a).split('.').pop();
		var bName = Type.getClassName(b).split('.').pop();

		// Sort the names alphabetically, so we don't end up with 2 join tables...
		var arr = [aName,bName];
		arr.sort(function(x,y) return Reflect.compare(x,y));

		// Join the names - eg join_SchoolClass_Student
		arr.unshift("_join");
		return arr.join('_');
	}

	#if server 
		@:access(sys.db.Manager)
		function setTableName(name:String)
		{
			manager.table_name = name;
		}
			
		@:access(sys.db.Manager)
		public function refreshList()
		{
			if (aObject != null)
			{
				var id = aObject.id;
				var aColumn = (isABeforeB()) ? "r1" : "r2";
				var bColumn = (isABeforeB()) ? "r2" : "r1";
				
				// var relationships = manager.search($a == id);
				var relationships = manager.unsafeObjects("SELECT * FROM `" + tableName + "` WHERE " + aColumn + " = " + Manager.quoteAny(id), false);
				if (relationships.length > 0)
				{
					var bListIDs = relationships.map(function (r:Relationship) { return Reflect.field(r, bColumn); });
					
					// Search B table for our list of IDs.  
					// bList = bManager.search($id in bListIDs);
					bList = bManager.unsafeObjects("SELECT * FROM `" + bManager.table_name + "` WHERE " + Manager.quoteList("id", bListIDs), false);
				}
			}
			if (bList == null)
			{
				bList = new List();
			}
		}
	#end
	
	/** Add a related object by creating a new Relationship on the appropriate join table.
	If the object you are adding does not have an ID, insert() will be called so that a valid
	ID can be obtained. */
	public function add(bObject:B)
	{
		if (bObject != null && bList.has(bObject) == false)
		{
			bList.add(bObject);

			#if server 
				if (bObject.id == null) bObject.insert();
				
				var r = if (isABeforeB()) new Relationship(aObject.id, bObject.id);
				        else              new Relationship(bObject.id, aObject.id);
				
				r.insert();
			#end
		}
	}

	public function remove(bObject:B)
	{
		if (bObject != null)
		{
			bList.remove(bObject);

			#if server 
				var aColumn = (isABeforeB()) ? "r1" : "r2";
				var bColumn = (isABeforeB()) ? "r2" : "r1";
				
				// manager.delete($a == aObject.id && $b == bObject.id);
				manager.unsafeDelete("DELETE FROM `" + tableName + "` WHERE " + aColumn + " = " + Manager.quoteAny(aObject.id) + " AND " + bColumn + " = " + Manager.quoteAny(bObject.id));
			#end 
		}
	}

	public function clear()
	{
		bList.clear();
		#if server 
			if (aObject != null)
			{
				var aColumn = (isABeforeB()) ? "r1" : "r2";
				// manager.delete($a == aObject.id);
				manager.unsafeDelete("DELETE FROM `" + tableName + "` WHERE " + aColumn + " = " + Manager.quoteAny(aObject.id));
			}
		#end 
	}

	public function setList(newBList:Iterable<B>)
	{
		clear();
		for (b in newBList)
		{
			add (b);
		}
	}

	public function iterator():Iterator<B>
	{
		return bList.iterator();
	}

	public function pop():B
	{
		if (bObject != null && aObject != null)
		{
			var bObject = bList.pop();

			#if server
				var aColumn = (isABeforeB()) ? "r1" : "r2";
				var bColumn = (isABeforeB()) ? "r2" : "r1";
				
				// manager.delete($a == aObject.id && $b == bObject.id);
				manager.unsafeDelete("DELETE FROM `" + tableName + "` WHERE " + aColumn + " = " + Manager.quoteAny(aObject.id) + " AND " + bColumn + " = " + Manager.quoteAny(bObject.id));
			#end 
		}

		return bObject;
	}

	public function push(bObject:B)
	{
		add(bObject);
	}
}


