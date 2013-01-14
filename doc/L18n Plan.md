Localisation
============

Numbers, currency, units etc
----------------------------

Thx provides a lot of things to do with numbers, currency, time etc.  Look into those.

Translation of compile-time strings
-----------------------------------

### The tr() function

We can import a simple tr() function globally that can then be used anywhere

    # Global Import
    import Localisation.tr()

And then anywhere in your code

    output = tr("Hello");

### Simple strings

    output = tr("Hello");

This will do a few things:

1. Add to default translation file: `<str id="Hello">Hello</str>`  
   Then in other languages (fr.xml): `<str id="Hello">Bonjour</str>`

2. In the code, replaces it with:

    1. If Localisation.runtimeSwitching = false, translate at macro time and return the translated string
       `Localisation.defaultLanguage.get('Hello').toExpr()`

       This allows you to use a compile time switch (-D en-us) to compile different version of your app for different locales, which will result in better runtime performance, albeit a little less runtime flexibility.

    2. Else, replace with Localisation.translate("Hello");

       Localisation.translate() will do:

           function translate (str) { 
               var s = getCurrentLanguage().get(str);
               if (s == null) getFallbackLanguage().get(str);
           }

       We could either load the Xml file at runtime, or have Haxe macros turn the Xml into a class with static members, which should have better runtime performance.

### Strings with more complex stuff

For something a bit more complex:

    output = tr('Hello $name, we've been expecting you');
    output = tr("Hello " + name + ", we've been expecting you");  // same thing

Add it to the translation file as

    <str id="Hello $name, we've been expecting you">Hello <name />, we've been expecting you</str>
    <str id="Hello $name, we've been expecting you">Bonjour <name />, nous vous attendions</str>

If we're doing comile time translation

	output = "Hello " + name + ", we've been expecting you";
	output = "Bonjour " + name + ", nous vous attendions";

If we're doing runtime translation, replace the expression:

    Localisation.translate("Hello $name, we've been expecting you", { name: name });

    function translate(str, variables)
    {
    	var s = getCurrentLanguage().get(str);
    		// xml.find('str[id=$str]').children(false);
    	for (varName in variables)
    	{
    		var varValue = variables.field(varName);
    		s.find(varName).replaceWith(varValue.parse());
    	}
    	return s.html();
    }

For anything other than a local variable, (so a function call, a property etc) don't allow compilation for now.  Later we can try allow it in terms of macros, but it will make the translation files look pretty ugly.

So if you had some object properties or methods, you'd have to turn them into local variables first:

    tr('Your name is $(user.firstName) and your birthday is $(getUserBirthday())'); // Would throw an error

    var name = user.firstName;
    var birthday = getUserBirthday();
    tr('Your name is $name and your birthday is $birthday'); // Compiles fine