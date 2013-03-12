package ufcommon.model.auth;

import ufcommon.db.Object;
import ufcommon.db.ManyToMany; 
#if server 
	import sys.db.Manager;
	import sys.db.Types;
#else 
	import ufcommon.db.Types;
#end

import ufcommon.model.auth.Permission;
import ufcommon.model.auth.User;

@:table("auth_group")
class Group extends Object
{
	public var name:SString<255>;

	public var users:ManyToMany<Group, User>;
	public var permissions:HasMany<Permission>;

	#if server 
		public static var manager:Manager<Group> = new Manager(Group);
	#end
}