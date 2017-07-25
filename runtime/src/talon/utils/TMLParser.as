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

		public static const KEYWORD_USE:String = "use";
		public static const KEYWORD_REF:String = "ref";
		public static const KEYWORD_UPDATE:String = "update";

		private var _templates:Object;
		private var _terminals:Vector.<String>;

		private var _usingTags:Object;
		private var _usingKeys:Object;

		private var _tags:Vector.<String>;
		private var _attributes:Vector.<Object>;

		/** @private */
		public function TMLParser(terminals:Vector.<String> = null, templates:Object = null)
		{
			_terminals = terminals || new Vector.<String>();
			_templates = templates || new Object();
			_usingTags = new Object();
			_usingKeys = new Object();
			_tags = new Vector.<String>();
			_attributes = new Vector.<Object>();
		}

		public function parse(xml:XML, tag:String = null):void
		{
			_tags.length = 0;
			if (tag) _tags[0] = tag;
			parseInternal(xml);
		}

		private function parseInternal(xml:XML):void
		{
			var kind:String = xml.nodeKind();
			if (kind != "element") return;

			var template:XML = null;
			var ref:String = null;
			var tag:String = xml.name();

			// If node is terminal - it can't be expanded - create node
			var isTerminal:Boolean = _terminals.indexOf(tag) != -1;
			if (isTerminal)
			{
				_tags[_tags.length] = tag;
				_attributes.push(fetchAttributes(xml));
				dispatch(EVENT_BEGIN);

				_tags.length = 0;
				_attributes.length = 0;
				for each (var child:XML in xml.children())
					parseInternal(child);

				dispatch(EVENT_END);
			}
			else if (tag == KEYWORD_USE)
			{
				ref = xml.attribute(KEYWORD_REF);
				if (ref == null) throw new Error("Tag '" + KEYWORD_USE + "' must contains '" + KEYWORD_REF + "' attribute");

				template = _templates[ref];
				if (template == null) throw new Error("Template with " + KEYWORD_REF + " = '" + ref + "' not found");

				_attributes.push(fetchAttributesFromUpdateField(xml));
				tag = getUsingTag(ref);
				if (tag) _tags[_tags.length] = tag;

				parseInternal(template);
			}
			else
			{
				ref = getUsingKey(tag);
				if (ref == null) throw new Error("Tag '" + tag + "' doesn't match any template");

				template = _templates[ref];
				if (template == null) throw new Error("Template with " + KEYWORD_REF + " = '" + ref + "' not found");

				_attributes.push(fetchAttributes(xml));
				_tags[_tags.length] = tag;

				parseInternal(template);
			}
		}

		//
		// Attributes (Static Methods)
		//

		/** Fetch attributes from XML to key-value pairs. */
		private static function fetchAttributes(xml:XML):Object
		{
			// NB! Use OrderedObject because there are compositor attributes
			// like padding & padding -Top, -Right, -Bottom, -Left
			// and for these attributes order is crucial value
			var result:Object = new OrderedObject();

			for each (var attribute:XML in xml.attributes())
			{
				var name:String = attribute.name();
				var value:String = attribute.toString();
				result[name] = value;
			}

			return result;
		}

		/** Fetch attributes from XML 'update' field. */
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

		//
		// Output
		//
		private function dispatch(type:String):void
		{
			var event:Event = new Event(type);
			dispatchEvent(event);
		}

		/** Current parse process stack of element types. */
		public function get tags():Vector.<String> { return _tags; }

		/** Current parse process stack of element attributes. */
		public function get attributes():Vector.<Object> { return _attributes; }

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