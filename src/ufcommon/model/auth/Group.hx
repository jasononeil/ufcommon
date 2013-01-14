package ufcommon.model.auth;

import ufcommon.db.Types;
import ufcommon.db.Object;
import ufcommon.db.ManyToMany;
#if server 
	import sys.db.Manager;
#end 

import ufcommon.model.auth.Permission;
import ufcommon.model.auth.User;

@:table("auth_group")
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
		
		#if server 
			var g = this;
			if (_permissions == null) _permissions = Permission.manager.search($group == g);
		#else 
			if (_permissions == null) _permissions = new List();
		#end

		return _permissions;
	}

	#if server 
		public static var manager:Manager<Group> = new Manager(Group);
	#end
}