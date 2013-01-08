package ufcommon.db;

import ufcommon.db.Object;
import ufcommon.db.Types;
import sys.db.Connection;

class Migration
{
	public var name:String;
	public function new()
	{
		name = Type.getClassName(Type.getClass(this));
	}

	public function up()
	{
		throw "Abstract method: please make sure your migrations implement the up() method...";
	}

	public function down()
	{
		throw "Abstract method: please make sure your migrations implement the down() method...";
	}

	//
	// Static API
	//

	static public function createTable(t:Class<sys.db.Object>)
	{
		var m = untyped t.manager;
		if ( !sys.db.TableCreate.exists(m) )
		{
			sys.db.TableCreate.create(m);
		}
	}

	static public function dropTable(t:Class<sys.db.Object>)
	{
		var manager = untyped t.manager;
		if ( !sys.db.TableCreate.exists(manager) )
		{
			function quote(v:String):String {
				return untyped manager.quoteField(v);
			}
			var cnx : Connection = untyped manager.getCnx();
			if( cnx == null )
				throw "SQL Connection not initialized on Manager";
			var dbName = cnx.dbName();
			var infos = manager.dbInfos();
			var sql = "DROP TABLE " + quote(infos.name);
			cnx.request(sql);
		}
	}
}