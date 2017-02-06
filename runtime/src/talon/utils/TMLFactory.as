package talon.utils
{
	import flash.events.Event;

	import talon.Attribute;
	import talon.Node;
	import talon.styles.StyleSheet;

	public class TMLFactory
	{
		public static const TAG_LIBRARY:String = "lib";
		public static const TAG_TEMPLATE:String = "def";
		public static const TAG_PROPERTIES:String = "properties";
		public static const TAG_STYLE:String = "style";

		public static const ATT_REF:String = "ref";
		public static const ATT_TAG:String = "tag";

		protected var _parser:TMLParser;
		protected var _parserStack:Array;
		protected var _parserProduct:*;
		protected var _parserLastTemplateRoot:Node;
		protected var _parserTag:String;

		protected var _resources:Object;
		protected var _linkage:Object;
		protected var _style:StyleSheet;

		public function TMLFactory(resources:Object = null):void
		{
			_resources = resources || {};
			_linkage = {};
			_style = new StyleSheet();

			_parserStack = new Array();
			_parser = new TMLParser();
			_parser.addEventListener(TMLParser.EVENT_BEGIN, onElementBegin);
			_parser.addEventListener(TMLParser.EVENT_END, onElementEnd);
		}

		//
		// Factory
		//
		public function create(source:Object, includeStyleSheet:Boolean, includeResources:Boolean):Object
		{
			var template:XML = null;

			if (source is XML) template = source as XML;
			else
			{
				template = _parser.templatesXML[source];

				for (var tag:String in _parser.templatesTag)
				{
					if (_parser.templatesTag[tag] == source)
					{
						_parserTag = tag;
						break;
					}
				}

				if (template == null) throw new ArgumentError("Template with id: " + source + " doesn't exist");
			}

			_parserLastTemplateRoot = null;
			_parserStack.length = 0;

			// Parse template, while parsing events dispatched (onElementBegin, onElementEnd)
			_parser.parse(template);
			var result:* = _parserProduct;
			var resultNode:Node = getElementNode(result);

			_parserLastTemplateRoot = null;
			_parserStack.length = 0;
			_parserProduct = null;

			// Add style and resources
			if (resultNode)
			{
				if (includeResources) resultNode.setResources(_resources);
				if (includeStyleSheet) resultNode.setStyleSheet(_style);
			}

			return result;
		}

		protected function onElementBegin(e:Event):void
		{
			var attributes:Object = _parser.cursorAttributes;


			if (attributes[Attribute.TYPE] == null)
				attributes[Attribute.TYPE] = _parserTag || _parser.cursorTags[0];

			_parserTag = null;

			// Create new element
			var elementClass:Class = getLinkageClass(_parser.cursorTags);
			var element:* = new elementClass();
			var elementNode:Node = getElementNode(element);

			// Save last template root (for binding purpose)
			if (_parserLastTemplateRoot == null || _parser.cursorTags.length>1)
				_parserLastTemplateRoot = elementNode;

			// Copy attributes to node
			if (elementNode)
				for (var key:String in attributes)
					setNodeAttribute(elementNode, key, attributes[key]);

			// Add to parent
			if (_parserStack.length)
			{
				var parent:* = _parserStack[_parserStack.length - 1];
				var child:* = element;
				addChild(parent, child);
			}

			_parserStack.push(element);
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
				var bindSourceAttribute:Attribute = _parserLastTemplateRoot.getOrCreateAttribute(bindSourceAttributeName);
				var bindTargetAttribute:Attribute = node.getOrCreateAttribute(attributeName);
				bindTargetAttribute.upstream(bindSourceAttribute);
			}
			else
			{
				node.setAttribute(attributeName, value);
			}
		}

		protected function getElementNode(element:*):Node
		{
			throw new Error("Not implemented");
		}

		protected function addChild(parent:*, child:*):void
		{
			throw new Error("Not implemented");
		}

		protected function onElementEnd(e:Event):void
		{
			_parserProduct = _parserStack.pop();
		}

		//
		// Linkage
		//
		/** Setup class which created for type of type. */
		public function setLinkage(type:String, typeClass:Class):void { _linkage[type] = typeClass; }

		//
		// Library
		//
		/** Add resource (image, string, etc.) to global factory scope. */
		public function addResourceToScope(id:String, resource:*):void { _resources[id] = resource; }

		/** Add all key-value pairs from object. */
		public function addResourcesToScope(object:Object):void { for (var id:String in object) addResourceToScope(id, object[id]); }

		/** Add css to global factory scope. */
		public function addStyleSheet(css:String):void { _style.parse(css); }

		/** Define type as terminal (see TML specification) */
		public function addTerminal(type:String, typeClass:Class):void { _parser.terminals.push(type); setLinkage(type, typeClass); }

		/** Add template (non terminal symbol) definition. Template name equals @res attribute. */
		public function addTemplate(xml:XML):void
		{
			var xmlName:String = xml.name();
			if (xmlName != TAG_TEMPLATE) throw new ArgumentError("Root node must be <" + TAG_TEMPLATE + ">");

			var ref:String = xml.attribute(ATT_REF);
			if (ref == null) throw new ArgumentError("Template must contains " + ATT_REF + " attribute");
			if (ref in _parser.templatesXML) throw new ArgumentError("Template with " + ATT_REF + " = '" + ref + "' already exists");

			var children:XMLList = xml.children();
			if (children.length() != 1) throw new ArgumentError("Template '" + ref + "' must contains one child");
			var tree:XML = children[0];

			var tag:String = xml.attribute(ATT_TAG);
			if (tag != null) _parser.templatesTag[tag] = ref;

			_parser.templatesXML[ref] = tree;
		}

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
						addStyleSheet(child.text());
						break;
					case TAG_PROPERTIES:
						addResourcesToScope(ParseUtil.parseProperties(child.text()));
						break;
					default:
						logger("Ignore library part", "'" + subtype + "'", "unknown type");
				}
			}
		}

		//
		// Utils
		//
		protected function logger(...args):void
		{
			var message:String = args.join(" ");
			trace("[TalonFactory]", message);
		}
	}
}