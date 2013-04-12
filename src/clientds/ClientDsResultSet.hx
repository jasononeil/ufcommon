package clientds;

import haxe.ds.StringMap;
import ufcommon.db.Object;
import sys.db.Types;

typedef ClientDsResultSet = Map<String, ObjectList>;
typedef ObjectList = List<Object>;
typedef TypedObjectList<T:ufcommon.db.Object> = List<T>;

class ClientDsResultSetExtractor
{
	static public function allItems(map:ClientDsResultSet):ObjectList
	{
		var all = new List();
		for (l in map)
		{
			for (o in l) all.push(o);
		}
		return all;
	}

	static public function items<T:Object>(map:ClientDsResultSet, model:Class<T>):TypedObjectList<T>
	{
		var name = Type.getClassName(model);
		return (map.exists(name)) ? cast map.get(name) : new List<T>();
	}

	static public function item<T:Object>(map:ClientDsResultSet, model:Class<T>, id:SUId):Null<T>
	{
		var name = Type.getClassName(model);
		if (map.exists(name))
		{
			var l:List<T> = cast map.get(name);
			return l.filter(function(o) return o.id == id).first();
		}
		return null;
	}
}
