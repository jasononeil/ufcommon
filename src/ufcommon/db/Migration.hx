package ufcommon.db;

import ufcommon.db.Object;
import ufcommon.db.Types;
import sys.db.Connection;
import sys.db.SpodInfos;

class Migration
{
	public var name:String;
	var upCommands:Array<String>;
	var downCommands:Array<String>;

	public function new()
	{
		name = Type.getClassName(Type.getClass(this));
		upCommands = [];
		downCommands = [];
	}

	public function change()
	{
		throw "Abstract method: please make sure your migrations implement the change() method...";
	}

	public function run(direction)
	{
		var cnx = sys.db.Manager.cnx;
		if( cnx == null )
			throw "SQL Connection not initialized on Manager";
		
		var commands = switch(direction) {
			case Up: upCommands;
			case Down: downCommands;
		}
		
		for (command in commands)
		{
			cnx.request(command);
		}
	}

	//
	// API to change DB Structure
	// Each of these generates the SQL for the change in both directions
	//

	function createTable(t:Class<sys.db.Object>, ?tableName:String)
	{
		var m:sys.db.Manager<sys.db.Object> = untyped t.manager;

		// Add the UP command
		upCommands.push(MigrationHelpers.createTableSql(m, tableName));
		
		// Add the DOWN command
		downCommands.push(MigrationHelpers.dropTableSql(m, tableName));
	}
}

class MigrationHelpers 
{
	// We need a manager, but managers are tied to a specific model, though that doesn't matter to us here.
	// For now I'll use the User manager, but a more generic solution would be nice
	static var manager = ufcommon.model.auth.User.manager;
	
	public static function quote(v:String):String {
		return untyped manager.quoteField(v);
	}

	public static inline function getTypeSQL( t : SpodType, dbName : String ) 
	{
		return sys.db.TableCreate.getTypeSQL(t, dbName);
	}

	public static function createTableSql(mngr:sys.db.Manager<sys.db.Object>, ?tableName:String, ?engine:String)
	{
		var cnx : Connection = sys.db.Manager.cnx;
		if( cnx == null )
			throw "SQL Connection not initialized on Manager";
		var dbName = cnx.dbName();

		var infos = mngr.dbInfos();
		if (tableName == null) tableName = infos.name;
		var sql = "CREATE TABLE " + quote(tableName) + " (";
		var decls = [];
		var hasID = false;
		for( f in infos.fields ) {
			switch( f.t ) {
			case DId:
				hasID = true;
			case DUId, DBigId:
				hasID = true;
				if( dbName == "SQLite" )
					throw "S" + Std.string(f.t).substr(1)+" is not supported by " + dbName + " : use SId instead";
			default:
			}
			decls.push(quote(f.name)+" "+getTypeSQL(f.t,dbName)+(f.isNull ? "" : " NOT NULL"));
		}
		if( dbName != "SQLite" || !hasID )
			decls.push("PRIMARY KEY ("+Lambda.map(infos.key,quote).join(",")+")");
		sql += decls.join(",");
		sql += ")";
		if( engine != null )
			sql += "ENGINE="+engine;

		return sql;
	}

	public static function dropTableSql(?mngr:sys.db.Manager<sys.db.Object>, ?tableName:String)
	{
		if (mngr == null && tableName == null) throw "dropTableSql requires you to give either a manager or a table name.";

		if (tableName == null)
		{
			var info = untyped mngr.dbInfos();
			tableName = info.name;
		}

		var sql = "DROP TABLE IF EXISTS " + quote(tableName);

		return sql;
	}
}

enum Direction {
	Up;
	Down;
}