package talon.utils
{
	import flash.events.EventDispatcher;

	public final class TMLParser extends EventDispatcher
	{
		// Events
		public static const EVENT_BEGIN:String = "begin";
		public static const EVENT_END:String = "end";

		// Special keyword-tags
		private static const TAG_TREE:String = "tree";
		private static const TAG_REWRITE:String = "rewrite";

		// Special keyword-attributes
		private static const ATT_TYPE:String = "type";
		private static const ATT_REF:String = "ref";

		// Types
		private static const TYPE_TREE:String = "tree";
		private static const TYPE_TREE_WITH_TYPE:String = "treeWithType";
		private static const TYPE_TERMINAL:String = "terminal";
		private static const TYPE_EMPTY:String = "empty";

		//
		// Implementation
		//
		private var _templatesById:Object;
		private var _templatesByType:Object;
		private var _terminals:Vector.<String>;

		private var _stack:TMLTemplateStack;

		public function TMLParser(terminals:Vector.<String>)
		{
			_terminals = terminals;
			_templatesById = new Object();
			_templatesByType = new Object();
			_stack = new TMLTemplateStack();
		}

		public function addTemplate(id:String, type:String, xml:XML):void
		{
			var template:TMLTemplate = new TMLTemplate(id, type, xml);
			_templatesById[id] = template;
			_templatesByType[type] = template;
		}

		public function parseTemplate(id:String):void
		{
			var template:TMLTemplate = _templatesById[id];

			_stack.purge();
			_stack.push(template);
			parse(template.xml, null, null);
		}

		private function parse(xml:XML, attributes:Object, rewrites:XMLList):void
		{
			var token:String = getNodeType(xml);
			var template:TMLTemplate = null;

			switch (token)
			{
				case TYPE_TREE:
					template = getTemplateByIdOrDie(getAttributeOrDie(xml, ATT_REF));
					_stack.push(template);
					parse(template.xml, fetchAttributes(xml, attributes, template.type, ATT_REF), null);
					_stack.pop();
					break;

				case TYPE_TREE_WITH_TYPE:
					template = getTemplateByTypeOrDie(xml.name());
					_stack.push(template);
					parse(template.xml, fetchAttributes(xml), null);
					_stack.pop();
					break;

				case TYPE_TERMINAL:

					var replacer:XML = _stack.getReplacer(xml);
					if (replacer)
					{
						parse(replacer, attributes, rewrites);
					}
					else
					{
						attributes = mergeAttributes(fetchAttributes(xml), _stack.getAttributes(xml), attributes);
						dispatchBegin(attributes);
						for each (var child:XML in _stack.getChildren(xml)) parse(child, null, null);
						dispatchEnd();
					}
					break;
			}
		}

		private function getNodeType(xml:XML):String
		{
			var name:String = xml.name();

			// Removed node via <rewrite>
			if (name == null)
				return TYPE_EMPTY;

			// Definition usage via <define> tag
			if (name == TAG_TREE)
				return TYPE_TREE;

			// Terminal node
			if (_terminals.indexOf(name) != -1)
				return TYPE_TERMINAL;

			// Definition usage via alias
			return TYPE_TREE_WITH_TYPE;
		}

		//
		// Utility methods
		//
		private function getTemplateByIdOrDie(id:String):TMLTemplate
		{
			var template:TMLTemplate = _templatesById[id];
			if (template == null) throw new Error("Template with id '" + id + "' not found");
			return template;
		}

		private function getTemplateByTypeOrDie(type:String):TMLTemplate
		{
			var template:TMLTemplate = _templatesByType[type];
			if (template == null) throw new Error("Template with type '" + type + "' not found");
			return template;
		}

		private function getAttributeOrDie(xml:XML, name:String):String
		{
			var attribute:XMLList = xml.attribute(name);
			if (attribute.length() == 0) throw new Error("XML doesn't has mandatory attribute " + name);
			return attribute.valueOf();
		}

		/** Fetch attributes from XML to key-value pairs. */
		private function fetchAttributes(xml:XML, force:Object = null, forceType:String = null, ...ignore):Object
		{
			var result:Object = new Object();

			// Type is only mandatory attribute
			result[ATT_TYPE] = forceType ? forceType : xml.name().toString();

			for each (var attribute:XML in xml.attributes())
			{
				var name:String = attribute.name();
				if (ignore.indexOf(name) != -1) continue;
				var value:String = attribute.toString();
				result[name] = value;
			}

			for (var key:String in force) result[key] = force[key];

			return result;
		}

		private function mergeAttributes(...sources):Object
		{
			var result:Object = new Object();

			for each (var source:Object in sources)
			{
				for (var key:String in source)
				{
					result[key] = source[key];
				}
			}

			return result;
		}

		private var _depth:int = 0;
		private function dispatchBegin(attributes:Object):void{ trace(mul("---", _depth), "<" + [attributes["type"], "#" + attributes["id"], attributes["color"]].join(" ") + ">"); _depth++ }
		private function dispatchEnd():void { _depth--; }
		function mul(str:String, value:int):String
		{
			var array:Array = new Array(value);
			for (var i:int = 0; i < value; i++) array[i] = str;
			return array.join("");
		}
	}
}

class TMLTemplateStack
{
	private var _stack:Vector.<TMLTemplate> = new <TMLTemplate>[];

	public function push(template:TMLTemplate):void
	{
		for each (var t:TMLTemplate in _stack)
		{
			if (t == template) throw new ArgumentError("Template is recursive nested");
		}

		_stack.push(template);
	}

	public function pop():void
	{
		_stack.pop();
	}

	public function purge():void
	{
		_stack.length = 0;
	}

	//
	// Rewrites affection
	//
	/** Return null if replacer not found. */
	public function getReplacer(xml:XML):XML
	{
		for (var i:int = _stack.length - 1; i >= 0; i--)
		{
			var replacer:XML = _stack[i].getReplacer(xml);
			if (replacer) return replacer;
		}

		return null;
	}


	public function getAttributes(xml:XML):Object
	{
		var sources:Array = [];
		for (var i:int = 0; i < _stack.length; i++)
		{
			sources.push(_stack[i].getAttributes(xml));
		}

		return mergeAttributes.apply(null, sources);
	}

	private function mergeAttributes(...sources):Object
	{
		var result:Object = new Object();

		for each (var source:Object in sources)
		{
			for (var key:String in source)
			{
				result[key] = source[key];
			}
		}

		return result;
	}

	public function getChildren(xml:XML):XMLList
	{
		return xml.children();
	}
}

class TMLTemplate
{
	private static const EMPTY:XML = new XML();

	private var _id:String;
	private var _type:String;
	private var _xml:XML;

	public function TMLTemplate(id:String, type:String, xml:XML)
	{
		_id = id;
		_type = type;
		_xml = xml;
	}

	public function getReplacer(xml:XML):XML
	{
		var id:String = xml.@id;
		var rewrite:XML = _xml.rewrite.(@ref==id).(@mode=="replace")[0];
		if (rewrite != null)
		{
			if (rewrite.children().length() > 1) throw new Error("Rewrite must have only one child");
			return rewrite.*[0] || EMPTY;
		}

		return null;
	}

	public function getAttributes(xml:XML):Object
	{
		var id:String = xml.@id;
		var rewrites:XMLList = _xml.rewrite.(@ref==id).(@mode=="attributes");
		
		var result:Object = new Object();
		for each (var rewrite:XML in rewrites)
		{
			for each (var attribute:XML in rewrite.attributes())
			{
				var name:String = attribute.name();
				var value:String = attribute.toString();
				if (name != "ref" && name != "mode")
				{
					result[name] = value
				}
			}
		}

		return result;
	}

	public function get xml():XML { return _xml }
	public function get id():String { return _id }
	public function get type():String { return _type }
}