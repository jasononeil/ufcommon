package ufcommon.view.admin;

import dtx.widget.Widget;
import dtx.widget.WidgetLoop;
using Detox;

class AdminView extends Widget {}

class MigrationListView extends Widget 
{
	public var loop:WidgetLoop<Class<ufcommon.db.Migration>>;

	public function new()
	{
		super();
		loop = new WidgetLoop(MigrationListView_ModelRow, "model");
		modelTable.append(loop);
	}
}

class MigrationListView_ModelRow extends Widget
{
	public var model:Class<ufcommon.db.Migration>;
}