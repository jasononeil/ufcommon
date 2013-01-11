package ufcommon.view.admin;

import dtx.widget.Widget;
import dtx.widget.WidgetLoop;
import ufcommon.db.Migration.MigrationResults;
using Detox;

class AdminView extends Widget {}

class MigrationListView extends Widget 
{
	public var runUp:WidgetLoop<String>;
	public var runDown:WidgetLoop<String>;
	public var alreadyRun:WidgetLoop<String>;

	public function new()
	{
		super();

		runUp = new WidgetLoop(MigrationListView_MigrationRowUp, "migration");
		runDown = new WidgetLoop(MigrationListView_MigrationRowDown, "migration");
		alreadyRun = new WidgetLoop(MigrationListView_MigrationRowDown, "migration");

		migrationsToRunUpList.append(runUp);
		migrationsToRunDownList.append(runDown);
		migrationsAlreadyRunList.append(alreadyRun);
	}

	public function addResults(mr:MigrationResults)
    {
        var resultsWidget = new MigrationListView_Results();
        resultsWidget.name = mr.name;
        
        for (r in mr.results)
        {
            var output = new MigrationListView_ResultsDisplay();
            output.statement = r.statement;
            output.result = r.result;
            resultsWidget.output.append(output);
        }

        this.results.append(resultsWidget);
        this.results.addClass("well");
    }
}