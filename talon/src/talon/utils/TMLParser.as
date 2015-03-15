package talon.utils
{
	import flash.events.EventDispatcher;

	public final class TMLParser extends EventDispatcher
	{
		// Events
		public static const EVENT_BEGIN:String = "begin";
		public static const EVENT_END:String = "end";

		// Special keyword-tags
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
		private static const TYPE_TERMINAL:String = "terminal";

		// Utils
		private static const EMPTY_XML:XML = new XML();
		private static const EMPTY_XML_LIST:XMLList = new XMLList();

		//
		// Implementation
		//
		private var _templates:Object;
		private var _terminals:Vector.<String>;

		private var _stack:Vector.<String>;

		public function TMLParser(scope:Object, terminals:Vector.<String>)
		{
			_terminals = terminals;
			_templates = scope;
			_stack = new Vector.<String>();
		}

		public function parseTemplate(id:String):void
		{
			var template:XML = getTemplateOrDie(id);

			push(id);
			parse(template, null, EMPTY_XML_LIST);
		}

		private function parse(xml:XML, attributes:Object, rewrites:XMLList):void
		{
			var token:String = getNodeType(xml);

			switch (token)
			{
				case TYPE_TREE:
					var templateId:String = xml.name();
					push(templateId);
					parse(getTemplateOrDie(xml.name()), fetchAttributes(xml), fetchRewrites(xml, rewrites));
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
					else if (replacer != EMPTY_XML)
					{
						parse(replacer, attributes, rewrites);
					}
					break;
			}
		}

		private function getNodeType(xml:XML):String
		{
			var name:String = xml.name();

			// Terminal node
			if (_terminals.indexOf(name) != -1)
				return TYPE_TERMINAL;

			// Definition usage via alias
			return TYPE_TREE;
		}

		private function push(id:String):void { if (_stack.indexOf(id) != -1) throw new Error("Template is recursive nested"); _stack.push(id); }
		private function pop():void { _stack.pop(); }

		//
		// Utility methods
		//
		private function getTemplateOrDie(id:String):XML
		{
			var template:XML = _templates[id];
			if (template == null) throw new Error("Template with type '" + id + "' not found");
			return template;
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