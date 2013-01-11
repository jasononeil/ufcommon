# Controlling Auth by Metadata

    // Requires user to be logged in for this controller or action.  Will redirect if they are not.
    @requireLogin

    // Require user to pass a test.  Will display an error message if they are not.
    @requireUserPassTest(someFn:User->Bool)
    @requireUserPassTests(someFn:User->AuthContext->Bool, someFn2:User->AuthContext->Bool)
	
	// Check that the current user has each of the listed permissions.  Will display an error message if they are not.
	@requirePermission(CanCook)
	@requirePermissions(CanCook, CanEat)

# Alternative plan

	Have Auth.* macros that are called within code:

	// Require a login, nothing else
	Auth.requireLogin()
		if (Auth.getUser() == null) throw AuthorizationError();

	// Require a specific permission, or a set of permissions, or any of the given permissions
	Auth.requirePermission(EditDocuments)
		if (Auth.getUser().can(EditDocuments) == false) throw AuthorizationError();
	Auth.requirePermission(EditDocuments, DeleteDocuments)
		if (Auth.getUser().can([EditDocuments, DeleteDocuments]) == false) throw AuthorizationError();		// same as:
		if (Auth.getUser().can(EditDocuments) && Auth.getUser().can(DeleteDocuments)) throw AuthorizationError();
	Auth.requirePermission(EditDocuments || DeleteDocuments)
		if (Auth.getUser().can(EditDocuments) || Auth.getUser().can(DeleteDocuments)) throw AuthorizationError();

	// Require something more custom...
	Auth.require($user.id == owner); 	
		if ((Auth.getUser().id == this.owner) == false) throw AuthorizationError();
	Auth.require($user.can(DeletePosts))
		if (Auth.getUser().can(DeletePosts) == false) throw AuthorizationError();
	Auth.require($user.id == owner || $user.isInGroup(group) && groupEditable); 
		if ((Auth.getUser().id == this.owner || (Auth.getUser().isInGroup(this.group) && this.groupEditable)) == false) throw AuthorizationError();
	Auth.require(userIsSleepy($user));
		if (userIsSleepy(Auth.getUser())) throw AuthorizationError();
		...
		function userIsSleepy(u:User):Bool { return u.name == "Jason"; }

	// Superuser should always be allowed
	Auth.require($user.id == owner);
		if ((Auth.getUser().id == this.owner || Auth.isSuperUser()) == false) throw AuthorizationError();

	These can then be called:

		* In any action on the controller
		* In the API
		* In the onAuthorisationSomething) of the controller
		* In the model on insert(), update() and delete()
		* In the model manager on the various ways of reading...

	We could possibly still allow metadata, but I feel this is much cleaner and much more powerful.  It also enforces that the code must be valid, where-as metadata could have unknown Permissions or generally odd things...