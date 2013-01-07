package ufcommon.view.dbadmin;

import dtx.widget.WidgetLoop;
using Detox;

class DBAdminView extends dtx.widget.Widget 
{
	public var loop:WidgetLoop<String>;

	public function new()
	{
		super();
		loop = new WidgetLoop(DBAdminView_ModelRow, "modelName");
		modelTable.append(loop);
	}
}