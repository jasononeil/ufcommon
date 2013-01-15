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
	public var permission:SString<255>;
	@:skip @:belongsTo(groupID)	public var group(get,set):Group;

	// The setters / getters for group.  Macro in future
	public var groupID:SInt;
	@:skip var _group:Group = null;
	function get_group()
	{
		#if server 
			if (_group == null && groupID != null) 
				_group = Group.manager.get(groupID);
		#end
		return _group;
	}
	function set_group(v:Group)
	{
		_group = v;
		if (v == null) throw "Group cannot be null";
		groupID = v.id;
		return _group;
	}

	public static function getPermissionID(e:EnumValue):String
	{
		var enumName = Type.getEnumName(Type.getEnum(e));
		return enumName + ":" + Type.enumConstructor(e);
	}

	#if server 
		public static function addPermission(g:Group, p:EnumValue)
		{
			var item = new Permission();
			item.permission = getPermissionID(p);
			item.group = g;
			item.insert();
		}

		public static function revokePermission(g:Group, p:EnumValue)
		{
			var pString = getPermissionID(p);
			var items = Permission.manager.search($groupID == g.id && $permission == pString);
			for (item in items)
			{
				item.delete();
			}
		}

		public static function checkGroupHasPermission(g:Group, p:EnumValue):Bool
		{
			var pString = getPermissionID(p);
			var count = Permission.manager.count($groupID == g.id && $permission == pString);
			return (count > 0) ? true : false;
		}

		public static function checkUserHasPermission(u:User, p:EnumValue)
		{

		}

		public static var manager:Manager<Permission> = new Manager(Permission);
	#end
}