package ufcommon.view.admin;

import dtx.widget.Widget;
import dtx.widget.WidgetLoop;
import ufcommon.db.Migration.MigrationResults;
using Detox;

class MigrationView extends Widget 
{
	public var runUp:WidgetLoop<String, MigrationView_MigrationRowUp>;
	public var runDown:WidgetLoop<String, MigrationView_MigrationRowDown>;
	public var alreadyRun:WidgetLoop<String, MigrationView_MigrationRowDown>;

	public function new()
	{
		super();

		runUp = new WidgetLoop(MigrationView_MigrationRowUp, "migration");
		runDown = new WidgetLoop(MigrationView_MigrationRowDown, "migration");
		alreadyRun = new WidgetLoop(MigrationView_MigrationRowDown, "migration");

		migrationsToRunUpList.append(runUp);
		migrationsToRunDownList.append(runDown);
		migrationsAlreadyRunList.append(alreadyRun);
	}

	public function addResults(mr:MigrationResults)
    {
        var resultsWidget = new MigrationView_Results();
        resultsWidget.name = mr.name;
        
        for (r in mr.results)
        {
            var output = new MigrationView_ResultsDisplay();
            output.statement = r.statement;
            output.result = r.result;
            resultsWidget.output.append(output);
        }

        this.results.append(resultsWidget);
        this.results.addClass("well");
    }
}