# Controlling Auth by Metadata

    // Requires user to be logged in for this controller or action
    @require_login

    // Require user to pass a test
    @require_user_check(someFn:User->Bool)
	
	// Check that the current user has each of the listed permissions
	@permission_required(CanCook, CanEat)

	// 
