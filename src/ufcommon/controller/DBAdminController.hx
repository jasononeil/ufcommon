package ufcommon.controller;
import ufront.web.mvc.Controller;
import ufront.web.mvc.ContentResult;
import ufront.web.mvc.DetoxResult;
import ufront.web.routing.RouteCollection;

import ufcommon.view.dbadmin.*;
import ufcommon.model.HxDatabaseState;

using Detox;

class DBAdminController extends Controller
{
    static public function addRoutes(routes:RouteCollection, ?prefix:String = "/dbadmin/")
    {
    	routes
        .addRoute(prefix, { controller : "DBAdminController", action : "index" } )
        .addRoute(prefix + "model/{model}", { controller : "DBAdminController", action : "viewModel" } )
        .addRoute(prefix + "model/{model}/run/{actionID}", { controller : "DBAdminController", action : "runAction" } )
		;
    }

    public function index() 
    {
        checkTableExists();
        var view = "<h1>Database Admin goes here!</h1>".parse();
        return new DetoxResult(view);
    }

    public function viewModel(model:String) 
    {
        var view = '<h1>View model: $model</h1>'.parse();
        return new DetoxResult(view);
    }

    public function runAction(model:String, actionID:String) 
    {
        var view = '<h1>Run action on $model: $actionID</h1>'.parse();
        return new DetoxResult(view);
    }

    function checkTableExists()
    {
        HxDatabaseState.manager.search(true,{ limit : 1 });
        // try 
        // {
        // }
        // catch (e:Dynamic)
        // {
        //     trace 
        // }

    }
}