package talon.utils
{
	import flash.events.Event;

	import talon.Attribute;
	import talon.Node;

	public class TalonFactoryBase
	{
		public static const TAG_LIBRARY:String = "lib";
		public static const TAG_TEMPLATE:String = "def";
		public static const TAG_PROPERTIES:String = "properties";
		public static const TAG_STYLE:String = "style";

		public static const ATT_REF:String = "ref";
		public static const ATT_TAG:String = "tag";

		protected var _parser:TMLParser;
		protected var _parserStack:Vector.<Object>;
		protected var _parserRoots:Vector.<Object>;

		protected var _resources:Object;
		protected var _linkage:Object;
		protected var _style:StyleSheet;

		public function TalonFactoryBase():void
		{
			_resources = {};
			_linkage = {};
			_style = new StyleSheet();

			_parserStack = new Vector.<Object>();
			_parserRoots = new Vector.<Object>();

			_parser = new TMLParser();
			_parser.addEventListener(TMLParser.EVENT_BEGIN, onElementBegin);
			_parser.addEventListener(TMLParser.EVENT_END, onElementEnd);
		}

		// Factory

		protected function createInternal(xmlOrKey:Object, includeStyleSheet:Boolean, includeResources:Boolean):Object
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
			_parserStack.length = 0;
			_parserRoots.length = 0;
			_parser.parse(template, templateTag);

			var result:* = _parserStack.pop();
			var resultNode:Node = getNode(result);

			resultNode.unfreeze();

			// Add style and resources
			if (resultNode)
			{
				if (includeResources) resultNode.setResources(_resources);
				if (includeStyleSheet) resultNode.setStyleSheet(_style);
			}

			// Result
			return result;
		}

		protected function onElementBegin(e:Event):void
		{
			// Create new element
			var elementClass:Class = getLinkageClass(_parser.tags);
			var element:* = new elementClass();
			var elementNode:Node = getNode(element);
			elementNode.freeze();

			// Copy attributes to node
			elementNode.setAttribute(Attribute.TYPE, _parser.tags[0]);

			for (var i:int = _parser.attributes.length-1; i >= 0; i--)
			{
				for (var key:String in _parser.attributes[i])
				{
					var value:String = _parser.attributes[i][key];

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
			if (_parserStack.length == 0 || _parser.attributes.length > 1)
				_parserRoots.push(element);

			// Add to parent
			if (_parserStack.length)
				addChild(_parserStack[_parserStack.length-1], element);

			_parserStack.push(element);
		}

		protected function onElementEnd(e:Event):void
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
			throw new Error("Not implemented");
		}

		protected function addChild(parent:*, child:*):void
		{
			throw new Error("Not implemented");
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
		public function addStyle(style:StyleSheet):void { _style.merge(style); }

		/** Add template (non terminal symbol) definition. Template name equals @res attribute. */
		public function addTemplate(xml:XML):void
		{
			var xmlName:String = xml.name();
			if (xmlName != TAG_TEMPLATE) throw new ArgumentError("Root node must be <" + TAG_TEMPLATE + ">");

			var ref:String = xml.attribute(ATT_REF);
			if (ref == false) throw new ArgumentError("Template must contains " + ATT_REF + " attribute");
			if (ref in _parser.templates) throw new ArgumentError("Template with " + ATT_REF + " = '" + ref + "' already exists");

			var children:XMLList = xml.children();
			if (children.length() > 1) throw new ArgumentError("Template '" + ref + "' can contains only one child");
			var tree:XML = children[0] || new XML();

			var tag:String = xml.attribute(ATT_TAG);
			if (tag != null) _parser.setUsing(ref, tag);

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
						addStyle(new StyleSheet(child.text()));
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
		public function importResources(object:Object):void { for (var id:String in object) addResource(id, object[id]); }
		
		// Cache
		
		public function getCache():Object
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
				var templateTag:String = _parser.getUsingTag(templateName);
				if (templateTag) cacheTemplate["tag"] = templateTag;

				_parser.parse(templateXML, templateTag);
			}
			
			function onParser(e:Event):void
			{
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

				e.stopImmediatePropagation();
			}

			_parser.removeEventListener(TMLParser.EVENT_BEGIN, onParser);
			_parser.removeEventListener(TMLParser.EVENT_END, onParser);

			// Styles
			
			var cacheStyles:Object = cache["styles"] = [];

			for (var selector:String in _style.selectors)
			{
				var cacheStyleSelector:Object = cacheStyles[cacheStyles.length] = { selector: selector }
				var cacheStyleProps:Object = cacheStyleSelector["attributes"] = [];

				for (var key:String in _style.selectors[selector])
					cacheStyleProps.push(key, _style.selectors[selector][key]);
			}

			// Properties

			// Result
			
			return cache;
		}
		
		public function setCache(object:Object):void
		{
			
		}
		
		// Utils

		protected function logger(...args):void
		{
			var message:String = args.join(" ");
			trace("[TalonFactory]", message);
		}
	}
}