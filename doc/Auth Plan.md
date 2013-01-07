# Controlling Auth by Metadata

    // Requires user to be logged in for this controller or action.  Will redirect if they are not.
    @requireLogin

    // Require user to pass a test.  Will display an error message if they are not.
    @requireUserPassTest(someFn:User->Bool)
    @requireUserPassTests(someFn:User->AuthContext->Bool, someFn2:User->AuthContext->Bool)
	
	// Check that the current user has each of the listed permissions.  Will display an error message if they are not.
	@requirePermission(CanCook)
	@requirePermissions(CanCook, CanEat)