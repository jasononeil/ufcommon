package ufcommon.controller.admin;
import ufront.web.mvc.Controller;
import ufront.web.mvc.ContentResult;
import ufront.web.mvc.DetoxResult;
import ufront.web.routing.RouteCollection;

class SpodAdminController extends Controller
{
    public function runSpodAdmin()
    {
        UFAdminController.checkAuth();
        #if neko 
        	spadm.AdminStyle.BASE_URL = "/ufadmin/db/";
            spadm.Admin.handler("/ufadmin/db/");
        #else 
            throw "I'm sorry, SPOD Admin only runs on Neko";
        #end
    }
}