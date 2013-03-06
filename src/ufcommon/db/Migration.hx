package ufcommon.db;

import ufcommon.db.Object;
#if server 
	import sys.db.Types;
#else 
	import ufcommon.db.Types;
#end
import sys.db.Connection;
import sys.db.RecordInfos;

@:table("_migrations")
class Migration extends Object
{
	public var name:SString<255>;
	@:skip public var upCommands:Array<String>;
	@:skip public var downCommands:Array<String>;
	@:skip public var results:Null<Array<{statement:String, result:String}>>;
	@:skip public var directionRun:Direction;

	var data:SText;

	public function new()
	{
		super();

		// To prevent child migration classes using their own manager, and hence getting a different table name, 
		// set the manager manually after the constructor.
		untyped _manager = Migration.manager;

		name = Type.getClassName(Type.getClass(this));
		upCommands = [];
		downCommands = [];
		results = [];
	}

	function unpack()
	{
		var d = haxe.Unserializer.run(this.data);
		this.results = d.results;
		this.downCommands = d.downCommands;
	}

	public function change()
	{
		throw "Abstract method: please make sure your migrations implement the change() method...";
	}

	public function run(direction)
	{
		directionRun = direction;

		var cnx = sys.db.Manager.cnx;
		if( cnx == null )
			throw "SQL Connection not initialized on Manager";
		
		var commands:Array<String>;

		// The way we retrieve our commands depends on the direction
		// On the way up, we call change(), and it gives us arrays of both up and down commands.
		// On the way down though, we get our objects not from a file but from the database.  And we don't use a specific
		// manager, we use the generic Migration.manager, because we cannot garauntee that the model will exist in our codebase
		// anymore.  Which means our objects are created as generic Migration objects,
		// not their original sub-class.  So they don't have the "change" method anymore.  The best way to deal with this at
		// the moment is to call unpack(), which reads out the down commands from the database just in time to run them.
		switch(direction) {
			case Up:
				change();
				commands = upCommands;
			case Down: 
				unpack();
				commands = downCommands;
		}
		
		var migResults:MigrationResults = { 
			name: this.name,
			results: []
		};
		// If a command fails, don't attempt any more, skip them.  FUTURE: attempt a rollback.
		var failure = false;  
		for (command in commands)
		{
			var result:String;
			try 
			{
				if (failure == false)
				{
					cnx.request(command);
					result = "Success.";
				}
				else result = "Skipped.";
			}
			catch (e:String)
			{
				result = e;
				failure = true;
			}
			migResults.results.push({statement:command, result:result});
		}

		// Either add or remove this item from the database so we know what we're up to.
		switch (direction)
		{
			case Up: 
				this.data = haxe.Serializer.run({ downCommands: downCommands, results: results });
				this.insert();
			case Down: 
				this.delete();
		}

		return migResults;
	}

	//
	// API to change DB Structure
	// Each of these generates the SQL for the change in both directions
	//

	public function createTable(t:Class<sys.db.Object>, ?tableName:String)
	{
		var m:sys.db.Manager<sys.db.Object> = untyped t.manager;

		// Add the UP command
		upCommands.push(MigrationHelpers.createTableSql(m, tableName));
		
		// Add the DOWN command (in reverse order so it steps backward when running DOWN)
		downCommands.unshift(MigrationHelpers.dropTableSql(m, tableName));
	}

	// ALTER TABLE `Student` ADD `rollGroupID` INT( 10 ) UNSIGNED NOT NULL 

	public static var manager = new sys.db.Manager<Migration>(Migration);
}

typedef MigrationResults = {
	name:String,
	results:Array<{ statement:String, result:String }>
}

class MigrationHelpers 
{
	// We need a manager, but managers are tied to a specific model, though that doesn't matter to us here.
	// We'll just use the manager for our Migration table :)
	static var manager = Migration.manager;
	
	public static function quote(v:String):String {
		return untyped manager.quoteField(v);
	}

	public static inline function getTypeSQL( t : RecordType, dbName : String ) 
	{
		return sys.db.TableCreate.getTypeSQL(t, dbName);
	}

	public static function getDBName()
	{
		var cnx : Connection = sys.db.Manager.cnx;
		if( cnx == null )
			throw "SQL Connection not initialized on Manager";
		return cnx.dbName();
	}

	public static function createTableSql(mngr:sys.db.Manager<sys.db.Object>, ?tableName:String, ?engine:String)
	{
		var dbName = getDBName();
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

	public static function addColumnSQL(name:String, t:RecordType, isNull:Bool)
	{
		var dbName = getDBName();
	}

	public static function dropColumnSQL(name:String, t:RecordType, isNull:Bool)
	{
		var dbName = getDBName();
	}
}

enum Direction {
	Up;
	Down;
}