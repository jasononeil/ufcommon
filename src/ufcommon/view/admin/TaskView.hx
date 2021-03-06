package ufcommon.view.admin;

import dtx.widget.Widget;
import dtx.widget.WidgetLoop;
import ufcommon.model.admin.AdminTaskLog;
using Detox;

class TaskView extends Widget 
{
	public var taskSets:WidgetLoop<AdminTaskSet, TaskSet>;
	public function new()
	{
		super();
		taskSets = new WidgetLoop(TaskSet, "taskSet");
		taskSetContainer.append(taskSets);
	}

}

class TaskSet extends Widget 
{
	@:isVar public var taskSet(default,set):AdminTaskSet;
	public var taskList:WidgetLoop<AdminTaskSet.Task, TaskSet_IndividualTask>;
	public var tasks(null,set):Array<AdminTaskSet.Task>;
	
	public function new()
	{
		super();
		taskList = new WidgetLoop(TaskSet_IndividualTask);
		taskListContainer.append(taskList);
	}

	public function set_tasks(tasks:Array<AdminTaskSet.Task>)
	{
		taskList.addList(tasks);
		for (t in tasks)
		{
			var loopItem:TaskSet_IndividualTask = cast taskList.findItem(t).dom;
			for (inputName in t.inputs)
			{
				var i = '<input type="text" name="task_${t.name}_$inputName" placeholder="$inputName" title="$inputName" />'.parse();
				loopItem.taskInputsContainer.append(i);
			}
		}
		return tasks;
	}

	public function set_taskSet(ts:AdminTaskSet)
	{
		taskSet = ts;
		// Add the inputs for this task set...
		for (inputName in ts.taskSetInputs)
		{
			var i = '<input type="text" name="ts_$inputName" placeholder="$inputName" title="$inputName" />'.parse();
			taskSetInputsContainer.append(i);
		}
		return ts;
	}
}

class TaskResultView extends Widget 
{
	public var results:WidgetLoop<{task:String, description:String, output:String, timeTaken:String}, TaskResultView_Result>;

	public function new()
	{
		super();
		taskSet = "My Task Set";
		results = new WidgetLoop(TaskResultView_Result);
		resultContainer.append(results);
	}

	public function addResult()
	{
		var w = new TaskResultView_Result();
	}
}