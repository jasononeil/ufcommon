package ufcommon.db;

import sys.db.Types;
import haxe.ds.StringMap;

using StringTools;
using Lambda;

/** Extended Database Object

Builds on sys.db.Object, but adds: a default unique ID (unsigned Int), as well as created and modified timestamps.

Also has methods to keep the timestamps up to date, and a generic "save" method when you're not sure if you need to insert or update.

This class also uses conditional compilation so that the objects can exist on non-server targets that have no 
access to sys.db.*, on these platforms the objects can be created and shared with remoting, and will be able to
save and fetch records through ClientDS.

We tell if it's a server platform by seeing checking for the #server define, so on your neko/php/cpp targets use `-D server`.

Two build macros will be applied to all objects that extends this class:

 * The first, is used to detects HasMany<T>, BelongsTo<T> and ManyToMany<A,B> types and 
sets them up as properties so they are handled correctly.
 * The second adds a "manager:sys.db.Manager" property on the server, or a "clientDS:clientds.ClientDs" property on the
 client, and initialises them.

Validation

override validate()

Security

override checkAuthRead()
override checkAuthWrite()

*/
#if server
	@noTable
#else
	@:keepSub
	@:rtti
#end 
@:autoBuild(ufcommon.db.DBMacros.setupDBObject())
class Object #if server extends sys.db.Object #end
{
	public var id:SUId;
	public var created:SDateTime;
	public var modified:SDateTime;

	#if server
		public function new()
		{
			super();
			validationErrors = new StringMap();
		}

		/** Updates the "created" and "modified" timestamps, and then saves to the database. */
		override public function insert()
		{
			if (this.checkAuthWrite())
			{
				if (this.validate())
				{
					this.created = Date.now();
					this.modified = Date.now();
					super.insert();
				}
				else {
					var errors = Lambda.array(validationErrors).join(", ");
					throw 'Data validation failed for $this: ' + errors;
				}
			}
			else throw 'You do not have permission to save object $this';
		}

		/** Updates the "modified" timestamp, and then saves to the database. */
		override public function update()
		{
			if (this.checkAuthWrite())
			{
				if (this.validate())
				{
					this.modified = Date.now();
					super.update();
				}
				else {
					var errors = Lambda.array(validationErrors).join(", ");
					throw 'Data validation failed for $this: ' + errors;
				}
			}
			else throw 'You do not have permission to save object $this';
		}
		
		/** Either updates or inserts the given record into the database, updating timestamps as necessary. 

		If `id` is null, then it needs to be inserted.  If `id` already exists, try to update first.  If that
		throws an error, it means that it is not inserted yet, so then insert it. */
		public function save()
		{
			if (id == null)
			{
				insert();
			}
			else
			{
				try 
				{
					untyped this._lock = true;
					update();
				}
				catch (e:Dynamic)
				{
					// It had an ID, but it wasn't in the DB... so insert it
					insert();
				}
			}
		}
	
	#else

		var _clientDS(default,never) : clientds.ClientDs<Dynamic>;
		public function new() 
		{
			validationErrors = new StringMap();
			setupClientDs();
		}

		function setupClientDs()
		{
			if( _clientDS == null ) untyped _clientDS = Type.getClass(this).clientDS;
		}

		public function delete() { 
			setupClientDs();
			return _clientDS.delete(this.id);
		}
		public function save() { 
			setupClientDs();
			return _clientDS.save(this);
		}
		public function refresh() { 
			setupClientDs();
			return _clientDS.refresh(this.id);
		}

		public inline function insert() { save(); }
		public inline function update() { save(); }
	
		public function toString()
		{
			var modelName = Type.getClassName(Type.getClass(this));
			return '$modelName#$id';
		}
	#end

	/** If a call to validate() fails, it will populate this map with a list of errors.  The key should
	be the name of the field that failed validation, and the value should be a description of the error. */
	@:skip public var validationErrors:StringMap<String>;

	/** A function to validate the current model.
	
	By default, this checks that no values are null unless they are Null<T> / SNull<T>, or if it the unique ID
	that will be automatically generated.  If any are null when they shouldn't be, the model fails to validate.

	It also looks for "validate_{fieldName}" functions, and if they match, it executes the function.  If the function
	throws an error or returns false, then validation will fail.

	If you override this method to add more custom validation, then we recommend starting with `super.validate()` and
	ending with `return (!validationErrors.keys.hasNext());`
	*/
	public function validate():Bool 
	{
		validationErrors = new StringMap();
		return (!validationErrors.keys().hasNext());
	}

	/** A function to check if the current user is allowed to read this object.  This always returns true, you should override it to be more useful */
	public function checkAuthRead():Bool { return true; }
	
	/** A function to check if the current user is allowed to save this object.  This always returns true, you should override it to be more useful */
	public function checkAuthWrite():Bool { return true; }


	/** An example hxSerializeFields array used for custom serializaton.  Each model should have it's own static field for this, generated by the build macro. */
	static var hxSerializeFields = ["id","created","modified"];
	
	/** Custom serialization.  It will serialize all fields listed in the model's static `hxSerializeFields` array, which should be generated by the build macro for each model. */
	@:access(ufcommon.db.ManyToMany)
	function hxSerialize( s : haxe.Serializer ) 
	{
		s.useEnumIndex = true;
		s.useCache = true;

		var fields:Array<String> = untyped Type.getClass(this).hxSerializeFields;
		for (f in fields)
		{
			if (f == "modified" || f == "created")
			{
				var date=Reflect.field(this, f);
				s.serialize((date!=null) ? date.getTime() : null);
			}
			else if (f.startsWith("ManyToMany"))
			{
				var m2m:ManyToMany<Dynamic,Dynamic> = Reflect.getProperty(this, "_" + f.substr(10));
				if (m2m!=null)
				{
					s.serialize(Type.getClassName(m2m.b));
					s.serialize(m2m.bListIDs);
				}
				else 
				{
					// Figure out the type by looking at hxRelationships
					var relArr:Array<String> = untyped Type.getClass(this).hxRelationships;
					
					// Field name, eg "classes"
					var fieldName = f.substr(10); 

					// Relationship info, eg "classes,ManyToMany,app.coredata.model.SchoolClass"
					var relEntry = relArr.filter(function (r) return r.startsWith(fieldName+","))[0]; 
					
					// Model name, eg "app.coredata.model.SchoolClass"
					var typeName = relEntry.split(",").pop();

					s.serialize(typeName);
					s.serialize(null);
				}
			}
			else
				s.serialize(Reflect.field(this, f));
		}
	}

	/** Custom serialization.  It will unserialize all fields listed in the model's static `hxSerializeFields` array, which should be generated by the build macro for each model. */
	@:access(ufcommon.db.ManyToMany)
	function hxUnserialize( s : haxe.Unserializer ) 
	{
		var fields:Array<String> = untyped Type.getClass(this).hxSerializeFields;
		for (f in fields)
		{
			if (f == "modified" || f == "created")
			{
				var time = s.unserialize();
				Reflect.setProperty(this, f, (time!=null) ? Date.fromTime(time) : null);
			}
			else if (f.startsWith("ManyToMany"))
			{
				var bName = s.unserialize();
				var bListIDs = s.unserialize();

				if (bName != null)
				{
					var b = Type.resolveClass(bName);
					if (bListIDs == null) bListIDs = new List();

					var m2m = new ManyToMany(this, b);
					m2m.bListIDs = bListIDs;
					m2m.bList = null;
					Reflect.setField(this, "_"+f.substr(10), m2m);
				}
			}
			else 
				Reflect.setProperty(this, f, s.unserialize());
		}
	}
}

/** BelongsTo relation 

You can use this as if the field is just typed as whatever T is, but the build macro here will set it up as a property and will link to the related object correctly.  

T must be a type that extends ufcommon.db.Object  */
typedef BelongsTo<T> = T;

/** HasMany relation 

This type is transformed into a property that lets you iterate over related objects.  Related objects are determined by a corresponding "BelongsTo<T>" in the related class.  The returned list is read only - to update it you must update the related property on each object.

T must be a type that extends ufcommon.db.Object */
typedef HasMany<T> = Iterable<T>;

/** HasOne relation 

This type is transformed into a property that lets you fetch a single related object.  Related objects are determined by a corresponding "BelongsTo<T>" in the related class.  The property is read only - to update it you must update the BelongsTo<> property on the related object.

T must be a type that extends ufcommon.db.Object */
typedef HasOne<T> = Null<T>;