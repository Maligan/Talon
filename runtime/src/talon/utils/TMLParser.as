package talon.utils
{
	import flash.events.Event;
	import flash.events.EventDispatcher;

	[Event(type="flash.events.Event", name="elementBegin")]
	[Event(type="flash.events.Event", name="elementEnd")]
	public final class TMLParser extends EventDispatcher
	{
		public static const EVENT_BEGIN:String = "elementBegin";
		public static const EVENT_END:String = "elementEnd";

		// Special keyword-tags
		private static const TAG_USE:String = "use";
		private static const TAG_REWRITE:String = "rewrite";

		// Special keyword-attributes
		private static const ATT_ID:String = "id";
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
		private var _tags:Vector.<String>;
		private var _attributes:Object;

		/** @private */
		public function TMLParser(terminals:Vector.<String> = null, templates:Object = null)
		{
			_terminals = terminals || new Vector.<String>();
			_templates = templates || new Object();
			_tags = new Vector.<String>();
		}

		public function parse(xml:XML):void
		{
			_tags.length = 0;
			parseInternal(xml, null, EMPTY_XML_LIST);
		}

		private function parseInternal(xml:XML, attributes:Object, rewrites:XMLList):void
		{
			var tag:String = xml.name();

			if (_tags.indexOf(tag) != -1) throw new Error("Template is recursive nested");

			_tags[_tags.length] = tag;

			// If node is terminal - it can't be expanded - create node
			var isTerminal:Boolean = _terminals.indexOf(tag) != -1;
			if (isTerminal)
			{
				var replacer:XML = getRewritesReplace(xml, rewrites);
				if (replacer == null)
				{
					attributes = mergeAttributes(fetchAttributes(xml), getRewritesAttributes(xml, rewrites), attributes);
					dispatchBegin(attributes);
					_tags.length = 0;
					for each (var child:XML in getRewritesContentOrChildren(xml, rewrites)) parseInternal(child, null, rewrites);
					dispatchEnd();
				}
				// If node must be replaced (by parent node rewrites) to another XML
				else if (replacer != EMPTY_XML)
				{
					// TODO: May be _tags.pop() ?
					parseInternal(replacer, attributes, rewrites);
				}
			}
			else if (tag == TAG_USE)
			{
				parseInternal(getTemplateOrDie(xml.@ref), null, fetchRewrites(xml, rewrites));
			}
			// Else if node is template
			else
			{
				parseInternal(getTemplateOrDie(tag), mergeAttributes(fetchAttributes(xml), attributes), fetchRewrites(xml, rewrites));
			}
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

		//
		// Attributes (Static Methods)
		//
		/** Fetch attributes from XML to key-value pairs. */
		private static function fetchAttributes(xml:XML):Object
		{
			var result:Object = new Object();

			for each (var attribute:XML in xml.attributes())
			{
				var name:String = attribute.name();
				var value:String = attribute.toString();
				result[name] = value;
			}

			return result;
		}

		private static function mergeAttributes(...sources):Object
		{
			var result:Object = new Object();

			for each (var source:Object in sources)
				for (var key:String in source)
					result[key] = source[key];

			return result;
		}

		//
		// Rewrites (Static Methods)
		//
		/** Fetch rewrites from xml. */
		private static function fetchRewrites(xml:XML, force:XMLList):XMLList
		{
			return xml.child(TAG_REWRITE) + force;
		}

		/** Get xml-replacer for current xml defined in rewrites. */
		private static function getRewritesReplace(xml:XML, rewrites:XMLList):XML
		{
			var replacers:XMLList = getRewrites(xml, rewrites, VAL_REPLACE);
			if (replacers.length() == 0) return null;

			var replacer:XML = replacers[replacers.length() - 1];
			if (replacer.children().length() > 1) throw new Error("Rewrite must have only one child");

			return replacer.chidren[0] || EMPTY_XML;
		}

		/** Get xml-children for current xml defined in rewrites. OR original children list if there is no content rewrites. */
		private static function getRewritesContentOrChildren(xml:XML, rewrites:XMLList):XMLList
		{
			var contents:XMLList = getRewrites(xml, rewrites, VAL_CONTENT);
			if (contents.length() == 0) return xml.children();
			return contents[contents.length() - 1].children();
		}

		/** Get xml-attributes for current xml defined in rewrites. */
		private static function getRewritesAttributes(xml:XML, rewrites:XMLList):Object
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

		private static function getRewrites(target:XML, rewrites:XMLList, mode:String):XMLList
		{
			var id:String = target.attribute(ATT_ID);
			// WARNING: There are literally constants (ATT_REF = @ref, ATT_MODE = @mode)
			return rewrites.(@ref==id).(@mode==mode);
		}

		//
		// Output
		//
		private function dispatchBegin(attributes:Object):void
		{
			_attributes = attributes;
			var event:Event = new Event(EVENT_BEGIN);
			dispatchEvent(event);
		}

		private function dispatchEnd():void
		{
			_attributes = null;
			var event:Event = new Event(EVENT_END);
			dispatchEvent(event);
		}

		/** Current parse process stack of element types. */
		public function get cursorTags():Vector.<String> { return _tags; }

		/** Current element attributes. */
		public function get cursorAttributes():Object { return _attributes; }

		//
		// Properties
		//
		/** Set of non terminal symbols (key - string, value - xml) */
		public function get templates():Object { return _templates; }

		/** Set of terminal symbols */
		public function get terminals():Vector.<String> { return _terminals; }
	}
}