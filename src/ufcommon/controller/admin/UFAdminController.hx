package ufcommon.controller.admin;
import ufront.web.mvc.Controller;
import ufront.web.mvc.ContentResult;
import ufront.web.mvc.DetoxResult;
import ufront.web.routing.RouteCollection;

import ufcommon.view.admin.AdminView;
import ufcommon.view.admin.*;
import ufcommon.db.Migration;

import ufcommon.model.auth.User;
import ufcommon.model.auth.Permission;
import ufcommon.auth.UserAuth;

import detox.DetoxLayout;

using Detox;
using Lambda;

class UFAdminController extends Controller
{
    public static var models:List<Class<Dynamic>> = new List();

    static var prefix = "/ufadmin";

    static public function addRoutes(routes:RouteCollection, ?p:String = "/admin")
    {
        if (p != null) prefix = p;
        routes
        .addRoute(prefix + "/", { controller : "UFAdminController", action : "index" } )
        .addRoute(prefix + "/migrations/", { controller : "UFMigrationController", action : "viewMigrations" } )
        .addRoute(prefix + "/migrations/run/", { controller : "UFMigrationController", action : "runMigrations" } )
        .addRoute(prefix + "/migrations/runsingle/up/", { controller : "UFMigrationController", action : "runMigrationUp" } )
        .addRoute(prefix + "/migrations/runsingle/down/", { controller : "UFMigrationController", action : "runMigrationDown" } )
        .addRoute(prefix + "/tasks/", { controller : "UFTaskController", action : "viewTasks" } )
        .addRoute(prefix + "/tasks/run/", { controller : "UFTaskController", action : "run" } )
        .addRoute(prefix + "/db", { controller : "SpodAdminController", action : "runSpodAdmin" } )
        .addRoute(prefix + "/db/{?*rest}", { controller : "SpodAdminController", action : "runSpodAdmin" } )
        .addRoute(prefix + "/{?*rest}", { controller : "UFAdminController", action : "notFound" } )
        ;
    }

    public function index() 
    {
        checkAuth();
        checkTablesExists();
        var view = new AdminView();
        return new DetoxResult(view, getLayout());
    }

    public function notFound() 
    {
        checkAuth();
        var view = "Page not found.".parse();
        return new DetoxResult(view, getLayout());
    }

    function checkTablesExists()
    {
        if (!sys.db.TableCreate.exists(Migration.manager)) sys.db.TableCreate.create(Migration.manager);
        if (!sys.db.TableCreate.exists(ufcommon.model.admin.AdminTaskLog.manager)) sys.db.TableCreate.create(ufcommon.model.admin.AdminTaskLog.manager);
    }

    public static function getLayout()
    {
        var template = CompileTime.readXmlFile("ufcommon/view/admin/layout.html");
        var layout = new DetoxLayout(template);
        layout.title = "Ufront Admin Console";
        layout.addStylesheet("/css/screen.css");

        var server = neko.Web.getClientHeader("Host");
        layout.head.append('<base href="http://$server$prefix/" />'.parse());
        return layout;
    }

    public static function checkAuth()
    {
        // Only check if tables already exist, otherwise, they're allowed in
        if (sys.db.TableCreate.exists(User.manager))
        {
            var permissionID = Permission.getPermissionID(UFAdminPermissions.CanAccessAdminArea);
            var permissions = Permission.manager.search($permission == permissionID);

            // If a group has this permission, and at least one member belongs to such a group.
            if (permissions.length > 0 && permissions.exists(function (p) { return p.group.users.length > 0; }))
            {
                UserAuth.requirePermission(UFAdminPermissions.CanAccessAdminArea);
            }
            // Else: assume stuff isn't set up yet and let them in without checking.
        }

    }
}