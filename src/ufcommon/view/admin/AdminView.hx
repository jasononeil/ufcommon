package ufcommon.view.admin;

import dtx.widget.Widget;
import dtx.widget.WidgetLoop;
using Detox;

class AdminView extends Widget {}

class MigrationListView extends Widget 
{
	public var loop:WidgetLoop<String>;

	public function new()
	{
		super();
		loop = new WidgetLoop(MigrationListView_ModelRow, "modelName");
		modelTable.append(loop);
	}
}