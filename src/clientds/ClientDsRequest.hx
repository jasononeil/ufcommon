package clientds;

import ufcommon.db.Object;
import sys.db.Types;
using Lambda;

class ClientDsRequest
{
	public var requests:Map<String, RequestsForModel>;
	public var empty:Bool;
	
	public function new() 
	{
		empty = true;
		requests = new Map();
	}

	public function get(model:Class<Object>, id:SUId) 
	{
		if (id != null)
		{
			empty = false;
			var r = getModelRequests(model);
			if (r.get.indexOf(id) == -1) r.get.push(id);
			else ('Do not need to add $id because it is already in there');
		}
		return this;
	}

	public function getMany(model:Class<Object>, ids:Array<SUId>) 
	{
		if (ids != null && ids.length > 0)
		{
			empty = false;
			var r = getModelRequests(model);
			for (id in ids)
			{
				if (r.get.indexOf(id) == -1) r.get.push(id);
				else ('Do not need to add $id because it is already in there');
			}
		}
		return this;
	}

	public function search(model:Class<Object>, criteria:{}) 
	{
		if (criteria != null)
		{
			empty = false;
			var r = getModelRequests(model);
			r.search.push(criteria);
		}
		return this;
	}

	public function all(model:Class<Object>) 
	{
		empty = false;
		var r = getModelRequests(model);
		r.all = true;
		return this;
	}

	public function allModels(models:Iterable<Class<Object>>) 
	{
		for (model in models)
		{
			all(model);
		}
		return this;
	}

	function getModelRequests(model:Class<Object>)
	{
		var name = Type.getClassName(model);
		if (requests.exists(name))
			return requests.get(name);
		else
		{
			var r = {
				all: false,
				search: [],
				get: []
			}
			requests.set(name, r);
			return r;
		}
	}

	public function toString()
	{
		var sb = new StringBuf();
		
		if (empty) sb.add("Empty");
		else
		{
			for (name in requests.keys())
			{
				var r = requests.get(name);

				if (r.all)
				{
					sb.add('$name.all() \n');
				}

				if (r.search.length > 0)
				{
					sb.add('$name.search():\n');
					for (s in r.search)
					{
						sb.add('  $s \n');
					}
				}

				if (r.get.length > 0)
				{
					sb.add('$name.get(${r.get.length} total): ${r.get} \n');
				}
			}
		}
		return sb.toString();
	}
}

typedef RequestsForModel = {
	all:Bool,
	search:Array<{}>,
	get:Array<SUId>
}