package ufcommon.controller.admin;
import ufront.web.mvc.Controller;
import ufront.web.mvc.ContentResult;
import ufront.web.mvc.DetoxResult;
import ufront.web.routing.RouteCollection;

import ufcommon.view.admin.AdminView;
import ufcommon.model.admin.HxDatabaseState;
import ufcommon.db.Migration;

import detox.DetoxLayout;

using Detox;

class AdminController extends Controller
{
    public static var models:List<Class<Dynamic>> = new List();

    static var prefix = "/admin";

    static public function addRoutes(routes:RouteCollection, ?p:String = "/admin")
    {
        if (p != null) prefix = p;
        routes
        .addRoute(prefix + "/", { controller : "AdminController", action : "index" } )
        .addRoute(prefix + "/migrations/", { controller : "AdminController", action : "viewMigrations" } )
        .addRoute(prefix + "/migrations/run/{name}", { controller : "AdminController", action : "runMigration" } )
        // .addRoute(prefix + "/model/{model}/run/{actionID}", { controller : "AdminController", action : "runAction" } )
        .addRoute(prefix + "/{?*rest}", { controller : "AdminController", action : "notFound" } )
        ;
    }

    public function index() 
    {
        checkTablesExists();
        var view = new AdminView();
        return new DetoxResult(view, getLayout());
    }

    public function notFound() 
    {
        var view = "Page not found.".parse();
        return new DetoxResult(view, getLayout());
    }

    public function viewMigrations()
    {
        var migrations:List<Class<Migration>> = cast CompileTime.getAllClasses(Migration);
        var view = new MigrationListView();
        view.loop.addList(migrations);
        return new DetoxResult(view, getLayout());
    }

    public function runMigration(name:String) 
    {
        var view = '<h1>Run this migration: $name</h1>'.parse();
        return new DetoxResult(view, getLayout());
    }

    // public function runAction(model:String, actionID:String) 
    // {
    //     var view = '<h1>Run action on $model: $actionID</h1>'.parse();
    //     return new DetoxResult(view, getLayout());
    // }

    function checkTablesExists()
    {
        if ( !sys.db.TableCreate.exists(HxDatabaseState.manager) )
        {
            sys.db.TableCreate.create(HxDatabaseState.manager);
        }
    }

    function getLayout()
    {
        var template = CompileTime.readXmlFile("ufcommon/view/admin/layout.html");
        var layout = new DetoxLayout(template);
        layout.title = "Ufront Admin Console";
        layout.addStylesheet("/css/screen.css");

        var server = neko.Web.getClientHeader("Host");
        layout.head.append('<base href="http://$server$prefix/" />'.parse());
        return layout;
    }
}