package ufcommon.view.admin;

import dtx.widget.WidgetLoop;
using Detox;

class AdminView extends dtx.widget.Widget 
{
	public var loop:WidgetLoop<String>;

	public function new()
	{
		super();
		loop = new WidgetLoop(AdminView_ModelRow, "modelName");
		modelTable.append(loop);
	}
}