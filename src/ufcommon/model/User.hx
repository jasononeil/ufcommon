package ufcommon.model;

import ufcommon.db.Object;
import ufcommon.db.Types;
import ufcommon.db.ManyToMany;
using Lambda;

interface IUser
{
	// Fields in the object
	var username:SString<20>;

	// Methods that are implemented:
	function insert():Void;
	function update():Void;
	function delete():Void;
}

class User extends Object, implements IUser
{
	public var username:SString<20>;
	public var salt:SString<32>;
	public var password:SString<32>;

	@:skip @:manyToMany		public var groups(get,null):ManyToMany<User, Group>;

	@:skip var _groups:ManyToMany<User, Group>;
	function get_groups()
	{
		if (_groups == null) _groups = new ManyToMany(this, Group);
		return _groups;
	}

	public function new(u:String, p:String)
	{
		super();
		this.username = u;
		this.salt = Random.string(32);
		this.password = generatePasswordHash(p, salt);
	}

	/** Check permissions.  if (myUser.can(DriveCar) && myUser.can(BorrowParentsCar)) { ... } */
	public function can(e:EnumValue)
	{
		var str = Type.enumConstructor(e);
		loadUserPermissions();
		return Lambda.has(allUserPermissions, str) ? true : false;
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
		#end
	}

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
	
}