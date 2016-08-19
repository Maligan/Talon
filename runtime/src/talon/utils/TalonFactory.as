package talon.utils
{
	import flash.events.Event;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;

	import talon.Attribute;
	import talon.Node;
	import talon.StyleSheet;

	public class TalonFactory
	{
		public static const TAG_LIBRARY:String = "library";
		public static const TAG_TEMPLATE:String = "template";
		public static const TAG_PROPERTIES:String = "properties";
		public static const TAG_STYLE:String = "style";

		public static const ATT_ID:String = "id";
		public static const ATT_TYPE:String = "type";

		protected var _parser:TMLParser;
		protected var _parserStack:Array;
		protected var _parserProduct:*;
		protected var _parserLastTemplateRoot:Node;

		protected var _linkageByDefault:Class;
		protected var _linkage:Dictionary = new Dictionary();
		protected var _resources:Object = new Dictionary();
		protected var _templates:Object = new Dictionary();
		protected var _style:StyleSheet = new StyleSheet();

		public function TalonFactory(linkageByDefault:Class):void
		{
			_linkageByDefault = linkageByDefault;
			_parserStack = new Array();

			_parser = new TMLParser(null, null);
			_parser.addEventListener(TMLParser.EVENT_BEGIN, onElementBegin);
			_parser.addEventListener(TMLParser.EVENT_END, onElementEnd);
		}

		//
		// Factory
		//
		public function create(id:String, includeStyleSheet:Boolean = true, includeResources:Boolean = true):*
		{
			var template:XML = _templates[id];
			if (template == null) throw new ArgumentError("Template with id: " + id + " doesn't exist");

			// Parse template, while parsing events dispatched (onElementBegin, onElementEnd)
			_parser.parse(template);
			var result:* = _parserProduct;
			var resultAsTalonElement:ITalonElement = result as ITalonElement;
			_parserLastTemplateRoot = null;
			_parserProduct = null;

			// Add style and resources
			if (resultAsTalonElement)
			{
				if (includeResources) resultAsTalonElement.node.setResources(_resources);
				if (includeStyleSheet) resultAsTalonElement.node.setStyleSheet(_style);
			}

			return result;
		}

		protected function onElementBegin(e:Event):void
		{
			var type:String = _parser.cursorTags[0];
			var attributes:Object = _parser.cursorAttributes;

			// If template doesn't provide CSS type - use tag name
			if (attributes[Attribute.TYPE] == null)
				attributes[Attribute.TYPE] = type;

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

		protected function getElementNode(element:*):Node
		{
			return element is ITalonElement ? ITalonElement(element).node : null;
		}

		protected function getLinkageClass(types:Vector.<String>):Class
		{
			for (var i:int = 0; i < types.length; i++)
			{
				var result:Class = _linkage[types[i]];
				if (result) return result;
			}

			return _linkageByDefault;
		}

		protected function setNodeAttribute(node:Node, attributeName:String, value:String):void
		{
			var bindPattern:RegExp = /@(\w+)/;
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

		protected function addChild(parent:*, child:*):void
		{
			throw new ArgumentError("Not implemented");
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
		public function addResource(id:String, resource:*):void { _resources[id] = resource; }

		/** Add all key-value pairs from object. */
		public function addResourcesFromObject(object:Object):void { for (var id:String in object) addResource(id, object[id]); }

		/** Add css to global factory scope. */
		public function addStyleSheet(css:String):void { _style.parse(css); }

		/** Define type as terminal (see TML specification) */
		public function addTerminal(type:String):void { _parser.terminals.push(type); }

		/** Add all archive content to factory (images, templates, css, etc.). */
		public function addArchiveContentAsync(bytes:ByteArray, complete:Function):void { throw new Error("Not implemented"); }

		/** Add template (non terminal symbol) definition. Template name equals @id attribute. */
		public function addTemplate(xml:XML):void
		{
			var type:String = xml.name();
			if (type != TAG_TEMPLATE) throw new ArgumentError("Root node must be <" + TAG_TEMPLATE + ">");

			var id:String = xml.attribute(ATT_ID);
			if (id == null) throw new ArgumentError("Template must contains " + ATT_ID + " attribute");
			if (id in _templates) throw new ArgumentError("Template with " + ATT_ID + " already exists, removeTemplate() first");

			var children:XMLList = xml.children();
			if (children.length() != 1) throw new ArgumentError("Template must contains one child");
			var template:XML = children[0];

			// Registry by template id
			_templates[id] = template;

			// Registry by type for reusable templates
			var type:String = xml.attribute(ATT_TYPE);
			if (type == null) throw new ArgumentError("Template must contains " + ATT_TYPE + " attribute");
			_parser.templates[type] = template;
		}

		public function removeTemplate(id:String):void
		{
			var template:XML = _templates[id];
			if (template == null) return;

			delete _templates[id];

			for (var tag:String in _parser.templates)
			{
				if (template == _parser.templates[tag])
				{
					delete _parser.templates[tag];
					break;
				}
			}
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
						addResourcesFromObject(StringParseUtil.parseProperties(child.text()));
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