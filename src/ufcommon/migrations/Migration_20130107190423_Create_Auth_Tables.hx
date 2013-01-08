package ufcommon.migrate;

import ufcommon.db.Migration;
import ufcommon.model.auth.*;

class Migration_20130107190423_Create_Auth_Tables extends Migration
{
	override public function change()
	{
		createTable(User);
		createTable(Group);
		createTable(Permission);

		// Create ManyToMany
		createTable(Relationship, ManyToMany.generateTableName(Group, User));
	}
}