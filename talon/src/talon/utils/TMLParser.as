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
		private static const ATT_ID:String = "id";
		private static const ATT_TYPE:String = "type";
		private static const ATT_MODE:String = "mode";
		private static const ATT_REF:String = "ref";

		// Special keyword-values
		private static const VAL_REPLACE:String = "replace";
		private static const VAL_CONTENT:String = "content";
		private static const VAL_ATTRIBUTES:String = "attributes";

		// Types
		private static const TYPE_TREE:String = "tree";
		private static const TYPE_TREE_WITH_TYPE:String = "treeWithType";
		private static const TYPE_TERMINAL:String = "terminal";
		private static const TYPE_EMPTY:String = "empty";

		// Utils
		private static const EMPTY_XML:XML = new XML();
		private static const EMPTY_XML_LIST:XMLList = new XMLList();

		//
		// Implementation
		//
		private var _templatesById:Object;
		private var _templatesByType:Object;
		private var _terminals:Vector.<String>;

		private var _stack:Vector.<String>;

		public function TMLParser(terminals:Vector.<String>)
		{
			_terminals = terminals;
			_templatesById = new Object();
			_templatesByType = new Object();
			_stack = new Vector.<String>();
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

			push(template.id);
			parse(template.xml, null, EMPTY_XML_LIST);
		}

		private function parse(xml:XML, attributes:Object, rewrites:XMLList):void
		{
			var token:String = getNodeType(xml);
			var template:TMLTemplate = null;

			switch (token)
			{
				case TYPE_TREE:
					template = getTemplateByIdOrDie(getAttributeOrDie(xml, ATT_REF));
					push(template.id);
					parse(template.xml, fetchAttributes(xml, attributes, template.type, ATT_REF), fetchRewrites(xml, rewrites));
					pop();
					break;

				case TYPE_TREE_WITH_TYPE:
					template = getTemplateByTypeOrDie(xml.name());
					push(template.id);
					parse(template.xml, fetchAttributes(xml), fetchRewrites(xml, rewrites));
					pop();
					break;

				case TYPE_TERMINAL:
					var replacer:XML = rewriteReplace(xml, rewrites);
					if (replacer == null)
					{
						attributes = mergeAttributes(fetchAttributes(xml), rewriteAttributes(xml, rewrites), attributes);
						dispatchBegin(attributes);
						for each (var child:XML in rewriteContent(xml, rewrites)) parse(child, null, rewrites);
						dispatchEnd();
					}
					else
					{
						parse(replacer, attributes, rewrites);
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

		private function push(id:String):void { if (_stack.indexOf(id) != -1) throw new Error("Template is recursive nested"); _stack.push(id); }
		private function pop():void { _stack.pop(); }

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

		/** Fetch rewrites from xml. */
		private function fetchRewrites(xml:XML, force:XMLList):XMLList
		{
			return xml.child(TAG_REWRITE) + force;
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

			return mergeAttributes(result, force);
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

		//
		// Rewrites
		//
		private function rewriteReplace(xml:XML, rewrites:XMLList):XML
		{
			var replacers:XMLList = getRewrites(xml, rewrites, VAL_REPLACE);
			if (replacers.length() == 0) return null;

			var replacer:XML = replacers[replacers.length() - 1];
			if (replacer.children().length() > 1) throw new Error("Rewrite must have only one child");

			return replacer.chidren[0] || EMPTY_XML;
		}

		private function rewriteContent(xml:XML, rewrites:XMLList):XMLList
		{
			var contents:XMLList = getRewrites(xml, rewrites, VAL_CONTENT);
			if (contents.length() == 0) return xml.children();
			return contents[contents.length() - 1];
		}

		private function rewriteAttributes(xml:XML, rewrites:XMLList):Object
		{
			var attributes:XMLList = getRewrites(xml, rewrites, VAL_ATTRIBUTES);
			if (attributes.length() == 0) return null;
			var result:Object = new Object();

			for each (var rewrite:XML in attributes)
			{
				for each (var attribute:XML in rewrite.attributes())
				{
					var name:String = attribute.name();
					if (name == ATT_REF) continue;
					if (name == ATT_MODE) continue;
					result[name] = attribute.toString();
				}
			}

			return result;
		}

		private function getRewrites(target:XML, rewrites:XMLList, mode:String):XMLList
		{
			var id:String = target.attribute(ATT_ID);
			return rewrites.(@ref==id).(@mode==mode); // XXX: @ref && @mode
		}

		//
		// Output
		//
		private var _depth:int = 0;
		private function dispatchBegin(attributes:Object):void{ trace(mul("---", _depth), "<" + [attributes["type"], "#" + attributes["id"], attributes["color"]].join(" ") + ">"); _depth++ }
		private function dispatchEnd():void { _depth--; }
		private function mul(str:String, value:int):String
		{
			var array:Array = new Array(value);
			for (var i:int = 0; i < value; i++) array[i] = str;
			return array.join("");
		}
	}
}

class TMLTemplate
{
	public var id:String;
	public var type:String;
	public var xml:XML;

	public function TMLTemplate(id:String, type:String, xml:XML)
	{
		this.id = id;
		this.type = type;
		this.xml = xml;
	}
}