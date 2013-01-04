package ufcommon.model;

import ufcommon.sys.db.Object;
import ufcommon.sys.db.Types;

interface IUser
{
	// Fields in the object
	var username:SString<20>;

	// Methods that are implemented:
	function insert():Void;
	function update():Void;
	function delete():Void;
}

#if server 
class User extends Object, implements IUser
{
	public var username:SString<20>;
	public var salt:SString<32>;
	public var password:SString<32>;

	public function new(u:String, p:String)
	{
		super();
		this.username = u;
		this.salt = Random.string(32);
		this.password = generatePasswordHash(p, salt);
	}

	public function getSafeObject()
	{
		return new SafeUser(this);
	}

	public static function generatePasswordHash(password:String, salt:String)
	{
		return PBKDF2.encode(password, salt, 500, 32);
	}
}
#else 
typedef User = SafeUser;
#end

/** UserSafe is a version of the User model that is safe to use on the client side - it does not store sensitive data. */
class SafeUser extends Object, implements IUser
{
	public var username:SString<20>;

	public function new(?u:User)
	{
		super();
		if (u != null)
		{
			this.id = u.id;
			this.username = u.username;
		}
	}

	public function getFullObject()
	{
		// return User.manager.get(id);
	}
}