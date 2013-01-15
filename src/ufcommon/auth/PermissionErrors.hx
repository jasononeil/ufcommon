package ufcommon.auth;

enum PermissionErrors 
{
	NotLoggedIn(msg:String);
	DoesNotHavePermission(msg:String);
}