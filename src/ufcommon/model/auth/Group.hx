package ufcommon.model.auth;

import ufcommon.db.Object;
import ufcommon.db.ManyToMany; 
import sys.db.Types;

import ufcommon.model.auth.Permission;
import ufcommon.model.auth.User;

@:table("auth_group")
class Group extends Object
{
	public var name:SString<255>;

	public var users:ManyToMany<Group, User>;
	public var permissions:HasMany<Permission>;
}