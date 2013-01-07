package ufcommon.model;

import ufcommon.db.Types;
import ufcommon.db.Object;
import ufcommon.db.ManyToMany;

import ufcommon.model.Permission;
import ufcommon.model.User;

class Group extends Object
{
	public var name:SString<255>;

	@:skip @:manyToMany		public var users(get,null):ManyToMany<Group, User>;
	@:skip @:hasMany		public var permissions(get,null):List<Permission>;

	@:skip var _users:ManyToMany<Group, User>;
	function get_users()
	{
		if (_users == null) _users = new ManyToMany(this, User);
		return _users;
	}

	@:skip var _permissions:List<Permission>;
	function get_permissions()
	{
		var g = this;
		if (_permissions == null) _permissions = Permission.manager.search($group == g);
		return _permissions;
	}

	public static var manager:sys.db.Manager<Group> = new sys.db.Manager(Group);
}