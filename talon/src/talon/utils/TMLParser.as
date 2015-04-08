package talon.utils
{
	import flash.events.Event;
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

		// Utils
		private static const EMPTY_XML:XML = new XML();
		private static const EMPTY_XML_LIST:XMLList = new XMLList();

		//
		// Implementation
		//
		private var _templates:Object;
		private var _terminals:Vector.<String>;
		private var _stack:Vector.<String>;
		private var _cursor:Object;

		/** @private */
		public function TMLParser(terminals:Vector.<String> = null, templates:Object = null)
		{
			_terminals = terminals || new Vector.<String>();
			_templates = templates || new Object();
			_stack = new Vector.<String>();
		}

		public function parseTemplate(id:String):void
		{
			// XXX: Clean after error? _stack.length = 0;
			parse(getTemplateOrDie(id), null, EMPTY_XML_LIST);
		}

		private function parse(xml:XML, attributes:Object, rewrites:XMLList):void
		{
			var type:String = xml.name();
			var isTerminal:Boolean = _terminals.indexOf(type) != -1;

			// If node can't be expanded - create node
			if (isTerminal)
			{
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
			}
			// Else if node is template
			else
			{
				push(type);
				parse(getTemplateOrDie(type), fetchAttributes(xml, attributes), fetchRewrites(xml, rewrites));
				pop();
			}
		}

		private function push(id:String):void
		{
			if (_stack.indexOf(id) != -1) throw new Error("Template is recursive nested");
			_stack.push(id);
		}

		private function pop():void
		{
			_stack.pop();
		}

		//
		// Utility methods
		//
		private function getTemplateOrDie(id:String):XML
		{
			var template:XML = _templates[id];
			if (template == null) throw new Error("Template with type '" + id + "' not found");
			return template;
		}

		/** Fetch attributes from XML to key-value pairs. */
		private function fetchAttributes(xml:XML, force:Object = null):Object
		{
			var result:Object = new Object();

			// Type is only mandatory attribute
			result[ATT_TYPE] = xml.name().toString();

			for each (var attribute:XML in xml.attributes())
			{
				var name:String = attribute.name();
				var value:String = attribute.toString();
				result[name] = value;
			}

			return mergeAttributes(result, force);
		}

		private function mergeAttributes(...sources):Object
		{
			var result:Object = new Object();

			for each (var source:Object in sources)
				for (var key:String in source)
					result[key] = source[key];

			return result;
		}

		//
		// Rewrites
		//
		/** Fetch rewrites from xml. */
		private function fetchRewrites(xml:XML, force:XMLList):XMLList
		{
			return xml.child(TAG_REWRITE) + force;
		}

		/** Get xml-replacer for current xml defined in rewrites. */
		private function rewriteReplace(xml:XML, rewrites:XMLList):XML
		{
			var replacers:XMLList = getRewrites(xml, rewrites, VAL_REPLACE);
			if (replacers.length() == 0) return null;

			var replacer:XML = replacers[replacers.length() - 1];
			if (replacer.children().length() > 1) throw new Error("Rewrite must have only one child");

			return replacer.chidren[0] || EMPTY_XML;
		}

		/** Get xml-children for current xml defined in rewrites. */
		private function rewriteContent(xml:XML, rewrites:XMLList):XMLList
		{
			var contents:XMLList = getRewrites(xml, rewrites, VAL_CONTENT);
			if (contents.length() == 0) return xml.children();
			return contents[contents.length() - 1];
		}

		/** Get xml-attributes for current xml defined in rewrites. */
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
			// XXX: @ref && @mode (ATT_REF, ATT_MODE)
			return rewrites.(@ref==id).(@mode==mode);
		}

		//
		// Output
		//
		private function dispatchBegin(attributes:Object):void
		{
			_cursor = attributes;
			var event:Event = new Event(EVENT_BEGIN);
			dispatchEvent(event);
			_cursor = null;
		}

		private function dispatchEnd():void
		{
			var event:Event = new Event(EVENT_END);
			dispatchEvent(event);
		}

		//
		// Properties
		//
		/** Set of non terminal symbols (key - string, value - xml) */
		public function get templates():Object
		{
			return _templates;
		}

		/** This is attached attributes data to EVENT_BEGIN event. (Moved here, because I don't use starling dispatcher/event and don't want create TMLEvent class). */
		public function get cursor():Object
		{
			return _cursor;
		}

		/** Set of terminal symbols */
		public function get terminals():Vector.<String>
		{
			return _terminals;
		}
	}
}