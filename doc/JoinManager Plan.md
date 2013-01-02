Join Plan
=========

JoinManager

 * Like sys.db.Manager
 * Looks for @:relation metadata (one-to-one)
 	* Automatically joins those tables (recursively, left outer join)
 	* Changes the way it reads results and creates objects to work with multiple tables
 		* Start with our object, read, but with prefix
 		* If it finds a @:relation, read with that prefix, save object to @:relation property
 		* If it finds more relations, keep going
 * 

HasMany

 * sys.db.Manager does this about right...
 * B.manager.search($a == a)

ManyToMany

 * A 
   LEFT JOIN A_B ON A_B.A = A.id
   LEFT_JOIN B ON A_B.B = B.id
   WHERE A.id = 3

Possible syntax

	@:manyToMany var students:List<Students>; // Macros take care of the rest?  Including @:ignore