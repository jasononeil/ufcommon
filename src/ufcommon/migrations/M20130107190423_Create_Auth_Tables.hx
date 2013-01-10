package ufcommon.migrations;

import ufcommon.db.*;
import ufcommon.model.auth.*;

class M20130107190423_Create_Auth_Tables extends Migration
{
	override public function change()
	{
		// Create key tables
		createTable(User);
		createTable(Group);
		createTable(Permission);

		// Create ManyToMany tables
		createTable(Relationship, ManyToMany.generateTableName(Group, User));
	}
}