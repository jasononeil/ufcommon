package ufcommon.admin.controller;
import ufront.web.mvc.Controller;
import ufront.web.mvc.ContentResult;
import ufront.web.mvc.DetoxResult;
import ufront.web.routing.RouteCollection;

import ufcommon.view.dbadmin.*;
import ufcommon.model.HxDatabaseState;

using Detox;

class AdminController extends Controller
{
    public static var models:List<Class<Dynamic>> = new List();

    static public function addRoutes(routes:RouteCollection, ?prefix:String = "/admin")
    {
    	routes
        .addRoute(prefix + "/", { controller : "AdminController", action : "index" } )
        .addRoute(prefix + "/model/{model}", { controller : "AdminController", action : "viewModel" } )
        .addRoute(prefix + "/model/{model}/run/{actionID}", { controller : "AdminController", action : "runAction" } )
		;
    }

    public function index() 
    {
        checkTableExists();
        var view = new DBAdminView();
        view.loop.addList(Lambda.map(models, function (t) { return Type.getClassName(t); }));
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
        if ( !sys.db.TableCreate.exists(HxDatabaseState.manager) )
        {
            sys.db.TableCreate.create(HxDatabaseState.manager);
        }
    }
}