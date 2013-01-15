package ufcommon.auth;

import ufront.auth.storage.SessionStorage;
import ufront.web.session.FileSession;
import ufront.auth.IAuthAdapter;
import ufront.auth.Auth;
import ufcommon.model.auth.User;
import ufcommon.auth.DBUserAuthAdapter;
import ufcommon.auth.PermissionErrors;

class UserAuth
{
	#if server
		/** Set to the number of seconds the session should last.  By default, value=0, which will end at the end of the session. */
		public static var sessionLength:Int = 0;

		static var _sessionStorage:SessionStorage<User>;
		public static function getSession()
		{
			if (_sessionStorage == null)
			{
				_sessionStorage = new SessionStorage(FileSession.create('sessions', sessionLength));
			}
			return _sessionStorage;
		}

		static var _auth:Auth<User>;
		public static function getAuth()
		{
			if (_auth == null)
			{
				_auth = new ufront.auth.Auth<User>(getSession());
			}
			return _auth;
		}

		public static function startSession(authAdapter:DBUserAuthAdapter)
		{
			var authResult = getAuth().authenticate(authAdapter);
			if (authResult.isvalid)
			{
				getSession().write(authResult.identity);
			}
			return authResult;
		}

		public static function endSession()
		{
			getAuth().clearIdentity();
		}

		public static var isLoggedIn(get,never):Bool;
		static function get_isLoggedIn()
		{
			return getAuth().hasIdentity() && getAuth().getIdentity() != null;
		}

		public static var user(get,never):User;
		static function get_user()
		{
			var auth = getAuth();
			if (auth.hasIdentity())
			{
				var user = auth.getIdentity();
				if (user != null) return user;
			}
			return null;
		}
	#end 
}