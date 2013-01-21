package ufcommon.auth;

@:keep enum PermissionErrors 
{
	NotLoggedIn(msg:String);
	DoesNotHavePermission(msg:String);
}