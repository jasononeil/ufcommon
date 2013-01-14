package ufcommon.model.auth;

import ufcommon.db.Types;
import ufcommon.db.Object;
import ufcommon.model.auth.Group;

@:table("auth_permission")
class Permission extends Object
{
	public var permission:SString<100>;
	@:relation(groupID)		public var group:Group;


	public static var manager:sys.db.Manager<Permission> = new sys.db.Manager(Permission);

	public static function addPermission(g, p:EnumValue)
	{
		var item = new Permission();
		item.group = g;
		item.permission = Type.enumConstructor(p);
		item.insert();
	}

	public static function revokePermission(g, p)
	{
		var pString = Type.enumConstructor(p);
		var items = Permission.manager.search($group == g && $permission == pString);
		for (item in items)
		{
			item.delete();
		}
	}

	public static function checkGroupHasPermission(g, p):Bool
	{
		var pString = Type.enumConstructor(p);
		var count = Permission.manager.count($group == g && $permission == pString);
		return (count > 0) ? true : false;
	}

	public static function checkUserHasPermission(u, p)
	{

	}
}