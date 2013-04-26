package clientds;

import ufcommon.db.Object;
import haxe.ds.*;

class ClientDsUtil
{
	public static function filterByCriteria(l:Iterable<Object>, criteria:{})
	{
		var matches = new IntMap<Object>();
		for (obj in l)
		{
			var match = true;
			for (field in Reflect.fields(criteria))
			{
				var criteriaValue = Reflect.field(criteria, field);
				var objValue = Reflect.getProperty(obj, field);
				if (criteriaValue != objValue)
				{
					match = false;
					break;
				}
			}
			if (match) matches.set(obj.id, obj);
		}
		return matches;
	}
}