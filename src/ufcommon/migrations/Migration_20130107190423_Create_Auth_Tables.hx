package ufcommon.migrate;

import ufcommon.db.Migration;
import ufcommon.model.auth.*;

class Migration_20130107190423_Create_Auth_Tables extends Migration
{
	override public function up()
	{
		Migration.createTable(User);
		Migration.createTable(Group);
		Migration.createTable(Permission);
	}

	override public function down()
	{
		Migration.dropTable(User);
		Migration.dropTable(Group);
		Migration.dropTable(Permission);
	}
}