package talon.utils
{
	import flash.events.Event;

	import talon.core.Attribute;
	import talon.core.Node;
	import talon.core.Style;

	/** External independent abstract factory class. */
	public class TalonFactoryBase
	{
		public static const TAG_LIBRARY:String = "lib";
		public static const TAG_TEMPLATE:String = "def";
		public static const TAG_PROPERTIES:String = "props";
		public static const TAG_STYLE:String = "style";

		public static const ATT_TAG:String = "tag";

		protected var _resources:Object;
		protected var _styles:Vector.<Style>;
		protected var _linkage:Object;
		
		protected var _parser:TMLParser;
		protected var _parserCache:Object;
		
		private var _parserStack:Vector.<Object>;
		private var _parserRoots:Vector.<Object>;
		private var _parserAttributes:Vector.<Object>;
		private var _parserTags:Vector.<String>;
		
		public function TalonFactoryBase():void
		{
			_resources = {};
			_linkage = {};
			_styles = new <Style>[];

			_parserCache = {};
			_parserStack = new Vector.<Object>();
			_parserRoots = new Vector.<Object>();

			_parser = new TMLParser();
			_parser.addEventListener(TMLParser.EVENT_BEGIN, onElementBegin);
			_parser.addEventListener(TMLParser.EVENT_END, onElementEnd);
		}

		// Factory

		// TODO: Roll back after errors? _stack & _roots
		protected function buildObject(xmlOrKey:Object, includeStyleSheet:Boolean, includeResources:Boolean):Object
		{
			if (xmlOrKey == null) throw new Error("Parameter xmlOrKey must be non-null");
			
			// Define
			var template:XML = null;
			var templateTag:String = null;
			var templateCached:Boolean = false;

			if (xmlOrKey is XML)
				template = xmlOrKey as XML;
			else if (xmlOrKey in _parserCache)
				templateCached = true;				
			else if (xmlOrKey is String)
			{
				template = _parser.templates[xmlOrKey];
				templateTag = _parser.getUseTag(xmlOrKey as String);
				if (template === null) throw new ArgumentError("Template with id: " + xmlOrKey + " doesn't exist");
			}

			// Parse template, while parsing events dispatched (onElementBegin, onElementEnd)
			if (templateCached)
			{
				for each (var event:CacheEvent in _parserCache[xmlOrKey])
				{
					_parserAttributes = event.attributes;
					_parserTags = event.tags;
					if (event.type == TMLParser.EVENT_BEGIN) onElementBegin();
					else if (event.type == TMLParser.EVENT_END) onElementEnd();
				}
			}
			else
			{
				_parserAttributes = _parser.attributes;
				_parserTags = _parser.tags;
				_parser.parse(template, templateTag);
			}

			// Get result
			var result:* = _parserStack.pop();
			
			// In case of empty template
			if (result == null) return null;
			
			var resultNode:Node = getNode(result);

			resultNode.unfreeze();

			// Add style and resources
			if (resultNode)
			{
				if (includeResources) resultNode.setResources(_resources);
				if (includeStyleSheet) resultNode.setStyles(_styles);
			}

			// Result
			return result;
		}

		private function onElementBegin(e:Event = null):void
		{
			// Create new element
			var elementClass:Class = getLinkageClass(_parserTags);
			var element:* = new elementClass();
			var elementNode:Node = getNode(element);
			elementNode.freeze();

			// Copy attributes to node
			elementNode.setAttribute(Attribute.TYPE, _parserTags[0]);

			for (var i:int = _parserAttributes.length-1; i >= 0; i--)
			{
				for (var key:String in _parserAttributes[i])
				{
					var value:String = _parserAttributes[i][key];

					var bindPattern:RegExp = /^@([\w_][\w\d_]+)$/;
					var bindSplit:Array = bindPattern.exec(value);
					var bindName:String = (bindSplit && bindSplit.length>1) ? bindSplit[1] : null;
					if (bindName)
					{
						var bindSource:Node = (i==0 && _parserRoots.length) ? getNode(_parserRoots[_parserRoots.length-1]) : elementNode;
						var bindSourceAttribute:Attribute = bindSource.getOrCreateAttribute(bindName);
						elementNode.getOrCreateAttribute(key).upstream(bindSourceAttribute);
					}
					else
					{
						elementNode.setAttribute(key, value);
					}
				}
			}

			// Save last template root (for binding purpose)
			if (_parserStack.length == 0 || _parserAttributes.length > 1)
				_parserRoots.push(element);

			// Add to parent
			if (_parserStack.length)
				addChild(_parserStack[_parserStack.length-1], element);

			_parserStack.push(element);
		}
		
		private function onElementEnd(e:Event = null):void
		{
			// Leave last element in stack
			if (_parserStack.length > 1)
			{
				var last:* = _parserStack[_parserStack.length-1];
				var lastRoot:* = _parserRoots[_parserRoots.length-1];

				if (last == lastRoot)
					_parserRoots.pop();

				_parserStack.pop();
			}
		}

		// For override
		
		protected function getNode(element:*):Node
		{
			throw new Error("Abstract method");
		}

		protected function addChild(parent:*, child:*):void
		{
			throw new Error("Abstract method");
		}

		// Linkage

		/** Define type as terminal (see TML specification) */
		public function setTerminal(type:String, typeClass:Class):void
		{
			if (_linkage[type] != null)
				throw new Error("Terminal + '" + type + "' already exist");
				
			_parser.terminals.push(type);
			_linkage[type] = typeClass;
		}

		/** While linkage type to non-terminal is hidden - this method is redundant. */
		protected final function getLinkageClass(types:Vector.<String>):Class
		{
			for (var i:int = 0; i < types.length; i++)
			{
				var result:Class = _linkage[types[i]];
				if (result) return result;
			}

			// This is not an exception this is assert
			// you can catch it only via manual erase
			// classes from linkage dictionary
			throw new Error("Can't find any linkage for chain: " + types.join());
		}

		// Register

		/** Add resource (image, string, etc.) to global factory scope. */
		public function addResource(id:String, resource:*):void { _resources[id] = resource; }
		
		/** Add style to global factory scope. */
		public function addStyle(styles:Vector.<Style>):void { _styles = _styles.concat(styles); }

		/** Add template (non terminal symbol) definition. Template name equals @res attribute. */
		public function addTemplate(xml:XML):void
		{
			var xmlName:String = xml.name();
			if (xmlName != TAG_TEMPLATE) throw new ArgumentError("Root node must be <" + TAG_TEMPLATE + ">");

			var ref:String = xml.attribute(TMLParser.KEYWORD_REF);
			if (ref == false) throw new ArgumentError("Template must contains " + TMLParser.KEYWORD_REF + " attribute");
			if (ref in _parser.templates) throw new ArgumentError("Template with " + TMLParser.KEYWORD_REF + " = '" + ref + "' already exists");

			var children:XMLList = xml.children();
			if (children.length() > 1) throw new ArgumentError("Template '" + ref + "' can contains only one child");
			var tree:XML = children[0] || new XML();

			var tag:String = xml.attribute(ATT_TAG);
			if (tag != null) _parser.setUse(ref, tag);

			_parser.templates[ref] = tree;
		}

		// Batch stuff import
		
		/** Add all templates and style sheets from library xml. */
		public function importLibrary(xml:XML):void
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
						addStyle(ParseUtil.parseCSS(child.text()));
						break;
					case TAG_PROPERTIES:
						importResources(ParseUtil.parseProperties(child.text()));
						break;
					default:
						logger("Ignore library part", "'" + subtype + "'", "unknown type");
				}
			}
		}

		/** Add all key-value pairs from object. */
		public function importResources(object:Object):void
		{
			for (var id:String in object)
				addResource(id, object[id]);
		}
		
		public function importCache(cache:Object):void
		{
			if (cache == null) throw new Error("Parameter cache must be non-null");
			if (cache["type"] != "application/x-talon-cache") throw new Error("Cache mimeType is invalid");
			
			// Templates
			var templates:Object = cache["templates"];
			
			for each (var template:Object in templates)
			{
				var ref:String = template["ref"];
				var tag:String = template["tag"];
				var build:Array = template["build"];

				var events:Vector.<CacheEvent> = _parserCache[ref] = new Vector.<CacheEvent>();

				for each (var command:Object in build)
				{
					var event:CacheEvent = events[events.length] = new CacheEvent();
					
					// Type
					event.type = command["type"];
					
					// Tags & Attributes
					if (event.type == "begin")
					{
						event.tags = Vector.<String>(command["tags"]);
						event.attributes = new <Object>[];

						for each (var list:Array in command["attributes"])
						{
							var cursor:Object = event.attributes[event.attributes.length] = new OrderedObject();
							
							for (var i:int = 0; i < list.length; i+=2)
							{
								var name:String = list[i];
								var value:String = list[i+1];
								cursor[name] = value;
							}
						}
					}
				}
			}

			// Styles
			for each (var styleObject:Object in cache["styles"])
			{
				var selector:String = styleObject["selector"];
				var attributes:Array = styleObject["attributes"];
				var style:Style = _styles[_styles.length] = new Style(selector);

				for (var j:int = 0; j < attributes.length; j+=2)
				{
					name = attributes[j];
					value = attributes[j+1];
					style.values[name] = value;
				}
			}
			
			// Resources
			importResources(cache["resources"]);
		}
		
		// Utils

		protected function logger(...args):void
		{
			var message:String = args.join(" ");
			trace("[TalonFactory]", message);
		}

		/** @private Create cache object for templates/styles/resources within factory */
		public function buildCache():Object
		{
			var cache:Object = { type: "application/x-talon-cache" };

			// Templates

			var cacheTemplates:Object = cache["templates"] = {};
			var cacheTemplate:Object;
			var cacheTemplateBuild:Array;

			_parser.addEventListener(TMLParser.EVENT_BEGIN, onParser, false, int.MAX_VALUE);
			_parser.addEventListener(TMLParser.EVENT_END, onParser, false, int.MAX_VALUE);

			for (var templateName:String in _parser.templates)
			{
				cacheTemplate = cacheTemplates[templateName] = { ref: templateName };
				cacheTemplateBuild = cacheTemplate["build"] = [];

				var templateXML:XML = _parser.templates[templateName];
				var templateTag:String = _parser.getUseTag(templateName);
				if (templateTag) cacheTemplate["tag"] = templateTag;

				_parser.parse(templateXML, templateTag);
			}

			function onParser(e:Event):void
			{
				e.stopImmediatePropagation();

				var event:Object = cacheTemplateBuild[cacheTemplateBuild.length] = { type: e.type };

				if (e.type == TMLParser.EVENT_BEGIN)
				{
					var tmp0:Array;
					var tmp1:Array;

					event["tags"] = _parser.tags.concat();
					event["attributes"] = tmp0 = [];

					for each (var attributes:Object in _parser.attributes)
					{
						tmp1 = tmp0[tmp0.length] = [];

						for (var name:String in attributes)
							tmp1.push(name, attributes[name])
					}
				}
			}

			_parser.removeEventListener(TMLParser.EVENT_BEGIN, onParser);
			_parser.removeEventListener(TMLParser.EVENT_END, onParser);

			// Styles

			var cacheStyles:Object = cache["styles"] = [];

			for each (var style:Style in _styles)
			{
				var cacheStyleSelector:Object = cacheStyles[cacheStyles.length] = { selector: style.selector };
				var cacheStyleProps:Object = cacheStyleSelector["attributes"] = [];

				for (var key:String in style.values)
					cacheStyleProps.push(key, style.values[key]);
			}

			// Resources

			var cacheResources:Object = cache["resources"] = {};

			for (key in _resources)
			{
				var value:* = _resources[key];
				if (value is String)
					cacheResources[key] = value;
			}

			// Result

			return cache;
		}
	}
}

class CacheEvent
{
	public var type:String;
	public var attributes:Vector.<Object>;
	public var tags:Vector.<String>;
}
