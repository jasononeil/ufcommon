Join Plan
=========

JoinManager

 * Like sys.db.Manager
 * Looks for @:relationm, @:join metadata (one-to-one)
 	* Automatically joins those tables (recursively, left outer join)
 	* Changes the way it reads results and creates objects to work with multiple tables
 		* Start with our object, read, but with prefix
 		* If it finds a @:relation, read with that prefix, save object to @:relation property
 		* If it finds more relations, keep going
 	* Prevent recursion if relation is to another row in the same table?

HasMany

 * sys.db.Manager does this about right...
 * B.manager.search($a == a)
 * Look for @:hasMany
 	* Turn var into a property, (get,null)
 	* Add private var _$name:$type
 	* Add get_$name():$type {
 	      if (_$name == null) _$name = MyModel.manager.search($schoolClass = this); // assuming this is an instance of SchoolClass and that the MyModel table has a "schoolClass:SchoolClass" property.
 	      return _$name;
 	  }

ManyToMany

 * Look for @:manyToMany var students:ManyToMany<SchoolClass, Student>;
 	* Turn var into a property, (get,null)
 	* Add private var _$name:$type
 	* Add get_$name():$type {
 	      if (_staff == null) _staff = new ManyToMany(this, StaffMember);
 	      return _$name;
 	  }
 * Use straight SQL in future:
   SELECT A.id, B.* FROM
   A 
   LEFT JOIN A_B ON A_B.A = A.id
   LEFT_JOIN B ON A_B.B = B.id
   WHERE A.id = 3

Possible syntax

	@:manyToMany var students:List<Students>; // Macros take care of the rest?  Including @:ignore