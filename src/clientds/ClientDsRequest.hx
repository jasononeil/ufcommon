package clientds;

import ufcommon.db.Object;
import sys.db.Types;

class ClientDsRequest
{
	public var requests:Map<String, RequestsForModel>;
	public var empty = true;
	
	public function new() 
	{
		requests = new Map();
	}

	public function get(model:Class<Object>, id:SUId, ?fetchRelations=true) 
	{
		if (id != null)
		{
			empty = true;
			var r = getModelRequests(model);
			r.get.push({ id:id, r:fetchRelations });
		}
		return this;
	}

	public function getMany(model:Class<Object>, ids:Array<SUId>, ?fetchRelations=true) 
	{
		if (ids != null)
		{
			empty = true;
			var r = getModelRequests(model);
			r.getMany.push({ ids:ids, r:fetchRelations });
		}
		return this;
	}

	public function search(model:Class<Object>, criteria:{}, ?fetchRelations=true) 
	{
		if (criteria != null)
		{
			empty = true;
			var r = getModelRequests(model);
			r.search.push({ c:criteria, r:fetchRelations });
		}
		return this;
	}

	public function all(model:Class<Object>, ?fetchRelations=true) 
	{
		empty = true;
		var r = getModelRequests(model);
		r.all = true;
		r.allRel = fetchRelations;
		return this;
	}

	public function allModels(models:Iterable<Class<Object>>, ?fetchRelations=true) 
	{
		for (model in models)
		{
			all(model, fetchRelations);
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
				allRel: false,
				search: [],
				get: [],
				getMany: []
			}
			requests.set(name, r);
			return r;
		}
	}
}

typedef RequestsForModel = {
	all:Bool,
	allRel:Bool,
	search:Array<{ c:{}, r:Bool }>,
	get:Array<{ id:SUId, r:Bool }>,
	getMany:Array<{ ids:Array<SUId>, r:Bool }>
}