package ufcommon.model.auth;

import ufcommon.db.Object;
import ufcommon.db.Types;
import ufcommon.db.ManyToMany;
#if server 
	import sys.db.Manager;
#end 
using Lambda;

@:table("auth_user")

class User extends Object
{
	public var username:SString<20>;
	public var salt:SString<32>;
	public var password:SString<32>;

	@:skip @:manyToMany		public var groups(get,null):ManyToMany<User, Group>;

	public function new(u:String, p:String)
	{
		super();
		#if server 
			this.username = u;
			this.salt = Random.string(32);
			this.password = generatePasswordHash(p, salt);
		#end 
	}

	@:skip var _groups:ManyToMany<User, Group>;
	function get_groups()
	{
		if (_groups == null) _groups = new ManyToMany(this, Group);
		return _groups;
	}

	/** Check permissions.  if (myUser.can(DriveCar) && myUser.can(BorrowParentsCar)) { ... } */
	public function can(e:EnumValue)
	{
		loadUserPermissions();
		var str = Permission.getPermissionID(e);
		return allUserPermissions.has(str);
	}

	@:skip var allUserPermissions:List<String>;
	function loadUserPermissions()
	{
		#if server 
			if (allUserPermissions == null)
			{
				var groupIDs = groups.map(function (g:Group) { return g.id; });
 				var permissionList = Permission.manager.search($groupID in groupIDs);
				allUserPermissions = permissionList.map(function (p:Permission) { return p.permission; });
			}
		#else 
			// If we are on the client, and don't already have a list, the assumption that we have no permissions is better than assuming we have some.
			if (allUserPermissions == null) allUserPermissions = new List();
		#end
	}

	#if server 
		public function removeSensitiveData()
		{
			this.salt = "";
			this.password = "";
			return this;
		}

		public static function generatePasswordHash(password:String, salt:String)
		{
			return PBKDF2.encode(password, salt, 500, 32);
		}

		public static var manager:Manager<User> = new Manager(User);
	#end
}