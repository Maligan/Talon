package talon.utils
{
	import flash.events.Event;

	import talon.Attribute;
	import talon.Node;
	import talon.utils.StyleSheet;

	public class TMLFactory
	{
		public static const TAG_LIBRARY:String = "lib";
		public static const TAG_TEMPLATE:String = "def";
		public static const TAG_PROPERTIES:String = "properties";
		public static const TAG_STYLE:String = "style";

		public static const ATT_REF:String = "ref";
		public static const ATT_TAG:String = "tag";

		protected var _parser:TMLParser;
		protected var _parserCache:Object;
		protected var _parserCursorTags:Vector.<String>;
		protected var _parserCursorAttributes:Object;
		protected var _parserProducts:Array;
		protected var _parserProduct:*;
		protected var _parserBindSource:Node;

		protected var _resources:Object;
		protected var _linkage:Object;
		protected var _style:StyleSheet;

		public function TMLFactory():void
		{
			_resources = {};
			_linkage = {};
			_style = new StyleSheet();

			_parserProducts = new Array();
			_parser = new TMLParser();
			_parser.addEventListener(TMLParser.EVENT_BEGIN, onElementBegin);
			_parser.addEventListener(TMLParser.EVENT_END, onElementEnd);
		}

		// Factory

		public function create(xmlOrKey:Object, includeStyleSheet:Boolean, includeResources:Boolean):Object
		{
			// Define
			var template:XML = null;
			var templateTag:String = null;

			if (xmlOrKey is XML)
				template = xmlOrKey as XML;
			else if (xmlOrKey is String)
			{
				template = _parser.templates[xmlOrKey];
				templateTag = _parser.getUsingTag(xmlOrKey as String);
			}

			if (template == null) throw new ArgumentError("Template with id: " + xmlOrKey + " doesn't exist");

			// Parse template, while parsing events dispatched (onElementBegin, onElementEnd)
			_parserBindSource = null;
			_parserProducts.length = 0;
			_parserProduct = null;
			_parserCursorAttributes = null;
			_parserCursorTags = null;

			if (_parserCache && xmlOrKey is String && _parserCache[xmlOrKey] != null) parseCache(xmlOrKey as String);
			else _parser.parse(template, templateTag);

			var result:* = _parserProduct;
			var resultNode:Node = getNode(result);

			_parserBindSource = null;
			_parserProducts.length = 0;
			_parserProduct = null;
			_parserCursorAttributes = null;
			_parserCursorTags = null;

			// Add style and resources
			if (resultNode)
			{
				resultNode.unfreeze();
				if (includeResources) resultNode.setResources(_resources);
				if (includeStyleSheet) resultNode.setStyleSheet(_style);
			}

			resultNode.unfreeze()

			// Result
			return result;
		}

		private function parseCache(name:String):void
		{
			var events:Array = _parserCache[name];

			for each (var event:Object in events)
			{
				if (event.type == TMLParser.EVENT_BEGIN)
				{
					_parserCursorAttributes = new OrderedObject();

					for each (var attribute:Object in event.attributes)
					{
						var key:String = attribute.key;
						var value:String = attribute.value;
						_parserCursorAttributes[key] = value;
					}

					_parserCursorTags = Vector.<String>(event.tags);
					onElementBegin(null);
				}
				else if (event.type == TMLParser.EVENT_END)
				{
					onElementEnd(null);
				}
			}
		}

		protected function onElementBegin(e:Event):void
		{
			var tags:Vector.<String> = _parserCursorTags || _parser.cursorTags;
			var attributes:Object = _parserCursorAttributes || _parser.cursorAttributes;

			if (attributes[Attribute.TYPE] == null)
				attributes[Attribute.TYPE] = tags[0];

			// Create new element
			var elementClass:Class = getLinkageClass(tags);
			var element:* = new elementClass();
			var elementNode:Node = getNode(element);
			elementNode.freeze();

			// Save last template root (for binding purpose)
			if (_parserBindSource == null || tags.length>1)
				_parserBindSource = elementNode;

			// Copy attributes to node
			if (elementNode)
				for (var key:String in attributes)
					setNodeAttribute(elementNode, key, attributes[key]);

			// Add to parent
			if (_parserProducts.length)
			{
				var parent:* = _parserProducts[_parserProducts.length - 1];
				var child:* = element;
				addChild(parent, child);
			}

			_parserProducts.push(element);
		}

		protected function getLinkageClass(types:Vector.<String>):Class
		{
			for (var i:int = 0; i < types.length; i++)
			{
				var result:Class = _linkage[types[i]];
				if (result) return result;
			}

			// This is not an error this is assert
			// you can catch it only via manual erase
			// classes from linkage dictionary
			throw new Error("Can't find any linkage for chain: " + types.join());
		}

		protected function setNodeAttribute(node:Node, attributeName:String, value:String):void
		{
			var bindPattern:RegExp = /^@([\w_][\w\d_]+)$/;
			var bindSplit:Array = bindPattern.exec(value);

			var bindSourceAttributeName:String = (bindSplit && bindSplit.length>1) ? bindSplit[1] : null;
			if (bindSourceAttributeName)
			{
				var bindSourceAttribute:Attribute = _parserBindSource.getOrCreateAttribute(bindSourceAttributeName);
				var bindTargetAttribute:Attribute = node.getOrCreateAttribute(attributeName);
				bindTargetAttribute.upstream(bindSourceAttribute);
			}
			else
			{
				node.setAttribute(attributeName, value);
			}
		}

		protected function onElementEnd(e:Event):void
		{
			_parserProduct = _parserProducts.pop();
		}

		// For override

		protected function getNode(element:*):Node
		{
			throw new Error("Not implemented");
		}

		protected function addChild(parent:*, child:*):void
		{
			throw new Error("Not implemented");
		}

		// Register

		/** Add all key-value pairs from object. */
		public function addResources(object:Object):void { for (var id:String in object) addResource(id, object[id]); }

		/** Add resource (image, string, etc.) to global factory scope. */
		public function addResource(id:String, resource:*):void { _resources[id] = resource; }

		/** Add css to global factory scope. */
		public function addStyle(css:String):void { _style.parse(css); }

		/** Define type as terminal (see TML specification) */
		public function addTerminal(type:String, typeClass:Class):void { _parser.terminals.push(type); _linkage[type] = typeClass; }

		/** Add template (non terminal symbol) definition. Template name equals @res attribute. */
		public function addTemplate(xml:XML):void
		{
			var xmlName:String = xml.name();
			if (xmlName != TAG_TEMPLATE) throw new ArgumentError("Root node must be <" + TAG_TEMPLATE + ">");

			var ref:String = xml.attribute(ATT_REF);
			if (ref == null) throw new ArgumentError("Template must contains " + ATT_REF + " attribute");
			if (ref in _parser.templates) throw new ArgumentError("Template with " + ATT_REF + " = '" + ref + "' already exists");

			var children:XMLList = xml.children();
			if (children.length() != 1) throw new ArgumentError("Template '" + ref + "' must contains one child");
			var tree:XML = children[0];

			var tag:String = xml.attribute(ATT_TAG);
			if (tag != null) _parser.setUsing(ref, tag);

			_parser.templates[ref] = tree;
		}

		public function setCache(cache:Object):void { _parserCache = cache }

		/** Add all templates and style sheets from library xml. */
		public function addLibrary(xml:XML):void
		{
			var type:String = xml.name();
			if (type != TAG_LIBRARY) throw new ArgumentError("Root node must be <" + TAG_LIBRARY + ">");

			for each (var child:XML in xml.children())
			{
				var subtype:String = child.name();

				switch (subtype)
				{
					case TAG_TEMPLATE:
						addTemplate(child);
						break;
					case TAG_STYLE:
						addStyle(child.text());
						break;
					case TAG_PROPERTIES:
						addResources(ParseUtil.parseProperties(child.text()));
						break;
					default:
						logger("Ignore library part", "'" + subtype + "'", "unknown type");
				}
			}
		}

		// Utils

		protected function logger(...args):void
		{
			var message:String = args.join(" ");
			trace("[TalonFactory]", message);
		}

		public function getCache():Object
		{
			// Replace default listeners
			_parser.removeEventListener(TMLParser.EVENT_BEGIN, onElementBegin);
			_parser.removeEventListener(TMLParser.EVENT_END, onElementEnd);
			_parser.addEventListener(TMLParser.EVENT_BEGIN, onElementBeginInner);
			_parser.addEventListener(TMLParser.EVENT_END, onElementEndInner);

			// Parse all templates
			var cache:Object = {};
			var events:Array;

			for (var key:String in _parser.templates)
			{
				cache[key] = events = [];
				var value:XML = _parser.templates[key];
				var valueTag:String = _parser.getUsingTag(key);
				_parser.parse(value, valueTag);
			}

			function onElementBeginInner(e:Event):void
			{
				var order:Array = [];

				for (key in _parser.cursorAttributes)
				{
					order.push({
						key: key,
						value: _parser.cursorAttributes[key]
					})
				}

				events.push({
					type: e.type,
					tags: _parser.cursorTags.concat(),
					attributes: order
				})
			}

			function onElementEndInner(e:Event):void
			{
				events.push({
					type: e.type
				})
			}

			// Restore listeners
			_parser.removeEventListener(TMLParser.EVENT_BEGIN, onElementBeginInner);
			_parser.removeEventListener(TMLParser.EVENT_END, onElementEndInner);
			_parser.addEventListener(TMLParser.EVENT_BEGIN, onElementBegin);
			_parser.addEventListener(TMLParser.EVENT_END, onElementEnd);

			// Result
			return cache;
		}
	}
}