package talon.utils
{
	public final class TMLParser
	{
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

		private var _onBegin:Function;
		private var _onEnd:Function;

		/** @private */
		public function TMLParser(terminals:Vector.<String> = null, templates:Object = null, onElementBegin:Function = null, onElementEnd:Function = null)
		{
			_terminals = terminals || new Vector.<String>();
			_templates = templates || new Object();
			_stack = new Vector.<String>();

			// Do not use EventDispatcher: can't success 'try { } catch { }' if error occurs in listeners
			_onBegin = onElementBegin;
			_onEnd = onElementEnd;
		}

		public function parse(xml:XML):void
		{
			_stack.length = 0;
			parseInternal(xml, null, EMPTY_XML_LIST);
		}

		private function parseInternal(xml:XML, attributes:Object, rewrites:XMLList):void
		{
			var type:String = xml.name();

			// If node can't be expanded - create node
			var isTerminal:Boolean = _terminals.indexOf(type) != -1;
			if (isTerminal)
			{
				var replacer:XML = rewriteReplace(xml, rewrites);
				if (replacer == null)
				{
					attributes = mergeAttributes(fetchAttributes(xml), rewriteAttributes(xml, rewrites), attributes);
					dispatchBegin(attributes);
					for each (var child:XML in rewriteContent(xml, rewrites)) parseInternal(child, null, rewrites);
					dispatchEnd();
				}
				else if (replacer != EMPTY_XML)
				{
					parseInternal(replacer, attributes, rewrites);
				}
			}
			// Else if node is template
			else
			{
				push(type);
				parseInternal(getTemplateOrDie(type), fetchAttributes(xml, attributes), fetchRewrites(xml, rewrites));
				pop();
			}
		}

		private function push(id:String):void
		{
			if (_stack.indexOf(id) != -1)
				throw new Error("Template is recursive nested");

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

		//
		// Attributes (Static Methods)
		//
		/** Fetch attributes from XML to key-value pairs. */
		private static function fetchAttributes(xml:XML, force:Object = null):Object
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
		private static function rewriteReplace(xml:XML, rewrites:XMLList):XML
		{
			var replacers:XMLList = getRewrites(xml, rewrites, VAL_REPLACE);
			if (replacers.length() == 0) return null;

			var replacer:XML = replacers[replacers.length() - 1];
			if (replacer.children().length() > 1) throw new Error("Rewrite must have only one child");

			return replacer.chidren[0] || EMPTY_XML;
		}

		/** Get xml-children for current xml defined in rewrites. */
		private static function rewriteContent(xml:XML, rewrites:XMLList):XMLList
		{
			var contents:XMLList = getRewrites(xml, rewrites, VAL_CONTENT);
			if (contents.length() == 0) return xml.children();
			return contents[contents.length() - 1].children();
		}

		/** Get xml-attributes for current xml defined in rewrites. */
		private static function rewriteAttributes(xml:XML, rewrites:XMLList):Object
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
			// TODO: @ref && @mode (ATT_REF, ATT_MODE)
			return rewrites.(@ref==id).(@mode==mode);
		}

		//
		// Output
		//
		private function dispatchBegin(attributes:Object):void
		{
			_onBegin(attributes);
		}

		private function dispatchEnd():void
		{
			_onEnd();
		}

		//
		// Properties
		//
		/** Set of non terminal symbols (key - string, value - xml) */
		public function get templates():Object
		{
			return _templates;
		}

		/** Set of terminal symbols */
		public function get terminals():Vector.<String>
		{
			return _terminals;
		}
	}
}