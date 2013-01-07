package ufront.web;

#if neko 
	typedef FileSession = neko.ufront.web.FileSession;
#elseif php 
	typedef FileSession = php.ufront.web.FileSession;
#end 
