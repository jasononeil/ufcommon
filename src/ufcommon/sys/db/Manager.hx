package ufcommon.sys.db;
class Manager extends sys.db.Manager
{
	public function setTableName(name:String)
	{
		table_name = quoteField(name);
		return this;
	}
}