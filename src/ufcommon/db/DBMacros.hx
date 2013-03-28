package ufcommon.db;
import haxe.macro.Context;
import haxe.macro.Expr;
import sys.db.RecordMacros;
using tink.macro.tools.MacroTools;
using Lambda;

class DBMacros
{
	macro public function setupRelations():Array<Field>
	{
		// trace ('Set up relations for class ${Context.getLocalClass().toString()}');
		
		var fields = Context.getBuildFields();
		var retFields:Array<Field> = null;

		// Loop over every field.
		// Because we alter the list, loop over a copy so we don't include any new fields.
		for (f in fields.copy())
		{
			// Check we're not dealing with any statics...
			if ((f.access.has(AStatic) || f.access.has(AMacro)) == false)
			{
				switch (f.kind)
				{
					case FVar(TPath(relType), _): 
						// See if this var is one of our relationship types, and if so, process it.
						switch (relType)
						{
							case { name: "BelongsTo", pack: _, params: [TPType(TPath(modelType))] }:
								retFields = processBelongsToRelations(fields, f, modelType);
							case { name: "HasMany", pack: _, params: [TPType(TPath(modelType))] }:
								retFields = processHasManyRelations(fields, f, modelType);
							case { name: "ManyToMany", pack: _, params: [TPType(TPath(modelA)), TPType(TPath(modelB))] }:
								retFields = processManyToManyRelations(fields, f, modelA, modelB);
							case _: 
						}
					// If they're trying to use a relation as a property, give an error
					case FProp(_, _, complexType, _):
						switch (complexType)
						{
							case TPath(t):
								switch (t.name)
								{
									case "HasMany" | "BelongsTo" | "HasOne":
										Context.error('On field `${f.name}`: ${t.name} can only be used with a normal var, not a property.', f.pos);
									default: 
								}
							case _:
						}
					case _:
				}
			}
		}
		return retFields;
	}

	static function processBelongsToRelations(fields:Array<Field>, f:Field, modelType:TypePath)
	{
		// Add skip metadata to the field
		f.meta.push({ name: ":skip", params: [], pos: f.pos });

		// Add the ID field(s)
		// FOR NOW: fieldNameID:SId
		// LATER:
			// base the name of the ident in our metadata
			// figure out the type by analysing the type given in our field, opening the class, and looking for @:id() metadata or id:SId or id:SUId
		fields.push({
			pos: f.pos,
			name: f.name + "ID",
			meta: [],
			kind: FVar("SUInt".asComplexType()),
			doc: 'The unique ID for field ${f.name}.  This is what is actually stored in the database',
			access: [APublic]
		});

		// Change to a property, retrieve field type.
		var fieldType:Null<ComplexType> = null;
		var model:ComplexType;
		switch (f.kind) {
			case FVar(t,e):
				fieldType = t;
				f.kind = FProp("get","set",t,e);
			case _: Context.error('On field `${f.name}`: BelongsTo can only be used with a normal var, not a property or a function.', f.pos);
		};
		
		// Add the private container field
		// generally _fieldName:T
		fields.push({
			pos: f.pos,
			name: "_" + f.name,
			meta: [{ name: ":skip", params: [], pos: f.pos }], // Add @:skip metadata to this
			kind: FVar(TPath(modelType)),
			doc: null, 
			access: [APrivate]
		});

		// Add the getter

		var getterBody:Expr;
		var privateIdent = ("_" + f.name).resolve();
		var idIdent = (f.name + "ID").resolve();
		if (Context.defined("neko") || Context.defined("php") || Context.defined("cpp"))
		{
			var modelPath = (modelType.pack.length == 0) ? modelType.name : (modelType.pack.join(".") + "." + modelType.name);
			var model = modelPath.resolve();
			getterBody = macro {
					if ($privateIdent == null && $idIdent != null)
						$privateIdent = $model.manager.get($idIdent);
				return $privateIdent;
			};
		}
		else getterBody = macro return $privateIdent;
		fields.push({
			pos: f.pos,
			name: "get_" + f.name,
			meta: [],
			kind: FieldType.FFun({
				ret: fieldType,
				params: [],
				expr: getterBody,
				args: []
			}),
			doc: null,
			access: [APrivate]
		});

		// Add the setter

		var setterBody = macro {
			$privateIdent = v;
			if (v == null) throw '${modelType.name} cannot be null';
			$idIdent = v.id;
			return $privateIdent;
		}
		fields.push({
			pos: f.pos,
			name: "set_" + f.name,
			meta: [],
			kind: FieldType.FFun({
				ret: fieldType,
				params: [],
				expr: setterBody,
				args: [{
					value: null,
					type: fieldType,
					opt: false,
					name: "v"
				}]
			}),
			doc: null,
			access: [APrivate]
		});

		return fields;
	}

	static function processHasManyRelations(fields:Array<Field>, f:Field, modelType:TypePath)
	{
		// Add skip metadata to the field
		f.meta.push({ name: ":skip", params: [], pos: f.pos });


		// change var to property (get,null)
		// Switch kind
		//  - if var, change to property (get,null), get the fieldType
		//  - if property or function, throw error.  (if they want to do something custom, don't use the macro)
		// Return the property
		var fieldType:Null<ComplexType> = null;
		switch (f.kind) {
			case FVar(t,e):
				fieldType = t;
				f.kind = FProp("get","null",t,e);
			case _: Context.error('On field `${f.name}`: HasMany can only be used with a normal var, not a property or a function.', f.pos);
		};
		
		// create var _propertyName (and skip)
		// Add the private container field
		// generally _fieldName:T
		var modelTypeSig:ComplexType = TPath(modelType);
		var iterableTypeSig:ComplexType = macro :Iterable<$modelTypeSig>;
		fields.push({
			pos: f.pos,
			name: "_" + f.name,
			meta: [{ name: ":skip", params: [], pos: f.pos }], // Add @:skip metadata to this
			kind: FVar(iterableTypeSig),
			doc: null, 
			access: [APrivate]
		});

		// Get the type of model we're dealing with
		switch (fieldType)
		{
			case TPath(p):
				if (p.params.length != 1) Context.warning('', f.pos);
			default:
		}

		// Get the various exprs used in the getter

		var ident = ("_" + f.name).resolve();
		var relationKey = null;
		var relationKeyMeta = getMetaFromField(f, ":relationKey");
		if (relationKeyMeta != null)
		{
			var rIdent = relationKeyMeta[0];
			switch (rIdent.expr)
			{
				case EConst(CIdent(r)):
					relationKey = "$" + r;
				case _:
			}
		}
		else
		{
			// From "SomeClass" model get "$someClassID" name
			var name = Context.getLocalClass().get().name;
			relationKey = "$" + name.charAt(0).toLowerCase() + name.substr(1) + "ID";
		}

		// create getter

		var getterBody:Expr;
		if (Context.defined("neko") || Context.defined("php") || Context.defined("cpp"))
		{
			var modelPath = (modelType.pack.length == 0) ? modelType.name : (modelType.pack.join(".") + "." + modelType.name);
			var model = modelPath.resolve();
			getterBody = macro {
				var s = this;
				if ($ident == null) $ident = $model.manager.search($i{relationKey} == s.id);
				return $ident;
			};
		}
		else getterBody = macro return $ident;
		fields.push({
			pos: f.pos,
			name: "get_" + f.name,
			meta: [],
			kind: FieldType.FFun({
				ret: fieldType,
				params: [],
				expr: getterBody,
				args: []
			}),
			doc: null,
			access: [APrivate]
		});

		return fields;
	}

	static function processManyToManyRelations(fields:Array<Field>, f:Field, modelA:TypePath, modelB:TypePath)
	{
		// Add skip metadata to the field
		f.meta.push({ name: ":skip", params: [], pos: f.pos });


		// change var to property (get,null)
		// Switch kind
		//  - if var, change to property (get,null), get the fieldType
		//  - if property or function, throw error.  (if they want to do something custom, don't use the macro)
		// Return the property
		var fieldType:Null<ComplexType> = null;
		switch (f.kind) {
			case FVar(t,e):
				fieldType = t;
				f.kind = FProp("get","null",t,e);
				// Create getter or setter
			case _: Context.error('On field `${f.name}`: ManyToMany can only be used with a normal var, not a property or a function.', f.pos);
		};
		
		// create var _propertyName (and skip)
		// Add the private container field
		// generally _fieldName:T
		fields.push({
			pos: f.pos,
			name: "_" + f.name,
			meta: [{ name: ":skip", params: [], pos: f.pos }], // Add @:skip metadata to this
			kind: FVar(fieldType),
			doc: null, 
			access: [APrivate]
		});

		// Get the various exprs used in the getter

		var ident = ("_" + f.name).resolve();
		
		// create getter

		var getterBody:Expr;
		var bModelPath = (modelB.pack.length == 0) ? modelB.name : (modelB.pack.join(".") + "." + modelB.name);
		var bModel = bModelPath.resolve();
		getterBody = macro {
			if ($ident == null) $ident = new ManyToMany(this, $bModel);
			return $ident;
		};
		fields.push({
			pos: f.pos,
			name: "get_" + f.name,
			meta: [],
			kind: FieldType.FFun({
				ret: fieldType,
				params: [],
				expr: getterBody,
				args: []
			}),
			doc: null,
			access: [APrivate]
		});

		return fields;
	}

	static function getMetaFromField(f:Field, name:String)
	{
		for (metaItem in f.meta)
		{
			if (metaItem.name == name) return metaItem.params;
		}
		return null;
	}
}