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

		private static const KEYWORD_USE:String = "use";
		private static const KEYWORD_REF:String = "ref";
		private static const KEYWORD_UPDATE:String = "update";

		//
		// Implementation
		//
		private var _templates:Object;
		private var _terminals:Vector.<String>;

		private var _usingTags:Object;
		private var _usingKeys:Object;

		private var _tags:Vector.<String>;
		private var _attributes:Object;

		/** @private */
		public function TMLParser(terminals:Vector.<String> = null, templatesXML:Object = null)
		{
			_terminals = terminals || new Vector.<String>();
			_templates = templatesXML || new Object();
			_usingTags = new Object();
			_usingKeys = new Object();
			_tags = new Vector.<String>();
		}

		public function parse(xml:XML, tag:String = null):void
		{
			_tags.length = 0;
			if (tag) _tags[0] = tag;
			parseInternal(xml, null);
		}

		private function parseInternal(xml:XML, attributes:Object):void
		{
			var kind:String = xml.nodeKind();
			if (kind == "text") throw new Error("Text elements doesn't supported - " + xml.valueOf());
			if (kind != "element") return;

			var tag:String = xml.name();
			if (_tags.indexOf(tag) != -1) throw new Error("Template is recursive nested");

			// If node is terminal - it can't be expanded - create node
			var isTerminal:Boolean = _terminals.indexOf(tag) != -1;
			if (isTerminal)
			{
				_tags[_tags.length] = tag;
				attributes = mergeAttributes(fetchAttributes(xml), attributes);
				dispatchBegin(attributes);
				_tags.length = 0;
				for each (var child:XML in xml.children()) parseInternal(child, null);
				dispatchEnd();
			}
			else
			{
				var ref:String = null;

				if (tag == KEYWORD_USE)
				{
					ref = xml.attribute(KEYWORD_REF);
					if (ref == null) throw new Error("Tag '" + KEYWORD_USE + "' must contains '" + KEYWORD_REF + "' attribute");
					attributes = mergeAttributes(fetchAttributesFromUpdateField(xml), attributes);
					tag = getUsingTag(ref);
					if (tag) _tags[_tags.length] = tag;
				}
				else
				{
					ref = getUsingKey(tag);
					if (ref == null) throw new Error("Tag '" + tag + "' doesn't match any template");
					attributes = mergeAttributes(fetchAttributes(xml), attributes);
					_tags[_tags.length] = tag;
				}

				var template:XML = _templates[ref];
				if (template == null) throw new Error("Template with " + KEYWORD_REF + " = '" + ref + "' not found");
				parseInternal(template, attributes);
			}
		}

		//
		// Attributes (Static Methods)
		//
		/** Fetch attributes from XML to key-value pairs. */
		private static function fetchAttributes(xml:XML):Object
		{
			var result:Object = new OrderedObject();

			for each (var attribute:XML in xml.attributes())
			{
				var name:String = attribute.name();
				var value:String = attribute.toString();
				result[name] = value;
			}

			return result;
		}

		private static function fetchAttributesFromUpdateField(xml:XML):Object
		{
			var result:Object = new OrderedObject();

			var update:String = xml.attribute(KEYWORD_UPDATE);
			if (update)
			{
				var split:Array = update.split(';');

				for each (var property:String in split)
				{
					property = trim(property);

					if (property.length > 0)
					{
						var splitProperty:Array = property.split(':');
						var name:String = trim(splitProperty[0]);
						var value:String = trim(splitProperty[1]);

						result[name] = value;
					}
				}
			}

			return result;
		}

		private static function trim(string:String):String
		{
			return string.replace(/^\s*|\s*$/gm, '');
		}

		private static function mergeAttributes(...sources):Object
		{
			// NB! Use OrderedObject because there are compositor attributes
			// like padding & padding -Top, -Right, -Bottom, -Left
			// and for these attributes order is crucial value
			var result:Object = new OrderedObject();

			for each (var source:Object in sources)
				for (var key:String in source)
					result[key] = source[key];

			return result;
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
		/** Set of terminal symbols */
		public function get terminals():Vector.<String> { return _terminals; }

		/** Set of non-terminal symbols (mapping from key to xml) */
		public function get templates():Object { return _templates; }

		//
		// Usings
		//

		public function getUsingTag(key:String):String { return _usingTags[key]; }
		public function getUsingKey(tag:String):String { return _usingKeys[tag]; }

		/** Store two way mapping {key; tag} and vice versa. */
		public function setUsing(key:String, tag:String):void
		{
			if (key) _usingTags[key] = tag;
			if (tag) _usingKeys[tag] = key;
		}
	}
}