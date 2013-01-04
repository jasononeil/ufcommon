package ufcommon.model;

import ufcommon.sys.db.Object;
import ufcommon.sys.db.Types;

class HxDatabaseState extends Object
{
	public var table:SString<255>;
	public var action:SString<255>;
	public var date:SDateTime;
	public var result:SText;

	public static var manager = new sys.db.Manager<HxDatabaseState>(HxDatabaseState);
}