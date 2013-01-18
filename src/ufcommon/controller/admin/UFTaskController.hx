package ufcommon.controller.admin;
import ufront.web.mvc.Controller;
import ufront.web.mvc.ContentResult;
import ufront.web.mvc.DetoxResult;
import ufront.web.routing.RouteCollection;

import ufcommon.view.admin.TaskView;
import ufcommon.AdminTaskSet;

import detox.DetoxLayout;
import haxe.CallStack;
using Detox;
using Lambda;
using ufcommon.util.TimeOfDayTools;

class UFTaskController extends Controller
{
    public function viewTasks()
    {
        var view = new TaskView();
        var taskSets:List<Class<AdminTaskSet>> = cast CompileTime.getAllClasses(AdminTaskSet);
        view.taskSets.addList(taskSets.map(function (ts) { return Type.createInstance(ts, []); }));
        return new DetoxResult(view, UFAdminController.getLayout());
    }

    public function run()
    {
        try 
        {
            var post = this.controllerContext.request.post;
            if (post.exists("taskSet"))
            {
                var tsName = post.get("taskSet");
                
                if (post.exists("runAll"))
                {
                    return runTaskSet(tsName);
                }
                else if (post.exists("task"))
                {
                    var taskName = post.get("task");
                    return runSingleTask(tsName, taskName);
                }
                else throw "Both taskSet and task must be given as POST parameters";
            }
            else throw "taskSet must be given as a GET parameter";
        }
        catch (e:String)
        {
            var callStack = CallStack.toString(CallStack.callStack());
            var exceptionStack = CallStack.toString(CallStack.exceptionStack());
            var output = '<h1>Error:</h1>
            <h4>$e</h4>
            <h5>Exception Stack:</h5>
            <pre>$exceptionStack</pre>';
            return new DetoxResult(output.parse(), UFAdminController.getLayout());
        }
    }

    function runTaskSet(tsName:String)
    {
        var ts = getTaskSet(tsName);

        var view = new TaskResultView();
        view.taskSet = ts.taskSetTitle;
        view.taskSetDescription = ts.taskSetDescription;
        
        for (task in ts.tasks)
        {
            var result = runTask(tsName, task.name);
            view.results.addItem({
                task: task.title,
                description: (task.description == "") ? "..." : task.description,
                output: result.result.output,
                timeTaken: result.timeTaken
            });
        }

        return new DetoxResult(view, UFAdminController.getLayout());
    }

    function runSingleTask(tsName:String, taskName:String)
    {
        var result = runTask(tsName, taskName);

        var view = new TaskResultView();

        view.taskSet = result.ts.taskSetTitle;
        view.taskSetDescription = result.ts.taskSetDescription;
        view.results.addItem({
            task: result.task.title,
            description: (result.task.description == "") ? "..." : result.task.description,
            output: result.result.output,
            timeTaken: result.timeTaken
        });

        return new DetoxResult(view, UFAdminController.getLayout());
    }

    function runTask(tsName:String, taskName:String)
    {
        var ts = getTaskSet(tsName);
        var post = this.controllerContext.request.post;
        
        // Get TaskSet inputs
        for (inputName in ts.taskSetInputs)
        {
            if (post.exists("ts_" + inputName))
            {
                var varValue = post.get("ts_" + inputName);
                if (varValue == "") throw 'The TaskSet input $inputName was empty';
                Reflect.setProperty(ts, inputName, varValue);
            }
            else throw 'The TaskSet input $inputName was missing';
        }

        // Get Task inputs
        var currentTask = ts.tasks.filter(function (t) { return t.name == taskName; }).first();
        var taskInputs = [];
        if (currentTask != null)
        {
            for (inputName in currentTask.inputs)
            {
                var postName = 'task_${taskName}_${inputName}';
                if (post.exists(postName))
                {
                    var varValue = post.get(postName);
                    if (varValue == "") 
                        throw 'The Task input $inputName was empty';
                    else 
                        taskInputs.push(varValue);
                    
                }
                else throw 'The Task input $inputName was missing';
            }
        }

        // Execute the task
        var startTime = Date.now().getTime();
        var result = ts.run(taskName, taskInputs);
        var timeTaken = Std.int((Date.now().getTime() - startTime) / 1000);
        var timeTakenStr = timeTaken.timeToString();

        return {
            ts: ts,
            task: currentTask,
            result: result,
            timeTaken: timeTakenStr
        };
    }

    var ts:AdminTaskSet;
    function getTaskSet(tsName:String)
    {
        if (ts == null)
        {
            var tsClass = Type.resolveClass(tsName);
            if (tsClass == null) throw "The TaskSet you asked for was not found: " + tsName;
            ts = untyped Type.createInstance(tsClass, []);
        }
        return ts;
    }
}