package ufcommon.model.auth;

import ufcommon.db.Types;
import ufcommon.db.Object;
import ufcommon.model.auth.Group;
#if server 
	import sys.db.Manager;
#end 

@:table("auth_group_permission")
class Permission extends Object
{
	public var permission:SString<100>;
	@:relation(groupID)		public var group:Group;

	#if server 
		public static function addPermission(g:Group, p:EnumValue)
		{
			var item = new Permission();
			item.group = g;
			item.permission = getPermissionID(p);
			item.insert();
		}

		public static function revokePermission(g:Group, p:EnumValue)
		{
			var pString = getPermissionID(p);
			var items = Permission.manager.search($group == g && $permission == pString);
			for (item in items)
			{
				item.delete();
			}
		}

		public static function checkGroupHasPermission(g:Group, p:EnumValue):Bool
		{
			var pString = getPermissionID(p);
			var count = Permission.manager.count($group == g && $permission == pString);
			return (count > 0) ? true : false;
		}

		public static function checkUserHasPermission(u:User, p:EnumValue)
		{

		}

		public static function getPermissionID(e:EnumValue):String
		{
			var enumName = Type.getEnumName(Type.getEnum(p));
			return enumName + ":" Type.enumConstructor(p);
		}

		public static var manager:Manager<Permission> = new Manager(Permission);
	#end
}