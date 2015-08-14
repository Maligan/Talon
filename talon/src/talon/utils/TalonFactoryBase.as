package talon.utils
{
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;

	import talon.Attribute;
	import talon.Node;
	import talon.StyleSheet;

	public class TalonFactoryBase
	{
		public static const TAG_LIBRARY:String = "library";
		public static const TAG_TEMPLATE:String = "template";
		public static const TAG_STYLE:String = "style";

		public static const ATT_ID:String = "id";
		public static const ATT_TAG:String = "tag";

		protected var _parser:TMLParser;
		protected var _parserProductStack:Array;
		protected var _parserProductStackNonTerminal:Array;
		protected var _parserProduct:*;

		protected var _linkageByDefault:Class;
		protected var _linkage:Dictionary = new Dictionary();
		protected var _resources:Object = new Dictionary();
		protected var _templates:Object = new Dictionary();
		protected var _style:StyleSheet = new StyleSheet();

		public function TalonFactoryBase(linkageByDefault:Class):void
		{
			_linkageByDefault = linkageByDefault;
			_parser = new TMLParser(null, null, onElementBegin, onElementEnd);
			_parserProductStack = new Array();
			_parserProductStackNonTerminal = new Array();
		}

		protected function setup(symbol:String, type:Class):void
		{
			addTerminal(symbol);
			setLinkage(symbol, type);
		}

		//
		// Factory
		//
		public function produce(id:String, includeStyleSheet:Boolean = true, includeResources:Boolean = true):*
		{
			var template:XML = _templates[id];
			if (template == null) throw new ArgumentError("Template with id: " + id + " doesn't exist");

			// Parse template, while parsing events dispatched (onElementBegin, onElementEnd)
			_parser.parse(template);
			var result:* = _parserProduct;
			var resultAsTalonElement:ITalonElement = result as ITalonElement;
			_parserProduct = null;

			// Add style and resources
			if (resultAsTalonElement)
			{
				if (includeResources) resultAsTalonElement.node.setResources(_resources);
				if (includeStyleSheet) resultAsTalonElement.node.setStyleSheet(_style);
			}

			return result;
		}

		protected function onElementBegin(attributes:Object):void
		{
			// Define element type
			var type:String = attributes["type"];
			var typeClass:Class = getLinkageClass(type);

			// Create new element
			var element:* = new typeClass();
			var elementNode:Node = getElementNode(element);

			// Copy attributes to node
			if (elementNode)
				for (var key:String in attributes)
					setNodeAttribute(elementNode, key, attributes[key]);

			// Add to parent
			if (_parserProductStack.length)
			{
				var parent:* = _parserProductStack[_parserProductStack.length - 1];
				var child:* = element;
				addChild(parent, child);
			}

			_parserProductStack.push(element);

			var isNonTerminal:Boolean = type in _parser.templates;
			if (isNonTerminal) _parserProductStackNonTerminal.push(element);
		}

		protected function getElementNode(element:*):Node
		{
			return element is ITalonElement ? ITalonElement(element).node : null;
		}

		protected function getLinkageClass(type:String):Class
		{
			var result:Class = _linkage[type];
			if (result) return result;

			var superType:String = _parser.templates[type].name();
			var superClass:Class = getLinkageClass(superType);
			return superClass || _linkageByDefault;
		}

		protected function setNodeAttribute(node:Node, attributeName:String, value:String):void
		{
			var bindPattern:RegExp = /@(\w+)/;
			var bindSplit:Array = bindPattern.exec(value);
			var bindTarget:String = bindSplit && bindSplit.length > 1 ? bindSplit[1] : null;

			if (bindTarget)
			{
				var parent:ITalonElement = _parserProductStackNonTerminal[_parserProductStackNonTerminal.length - 1] as ITalonElement;
				var source:Attribute = parent.node.getOrCreateAttribute(bindTarget);
				var target:Attribute = node.getOrCreateAttribute(attributeName);

				var toTarget:Binding = Binding.bind(source.change, source, "value", target, "setted");
				toTarget.trigger();
				var toSource:Binding = Binding.bind(target.change, target, "value", source, "setted");

				parent.node.addBinding(toTarget);
				parent.node.addBinding(toSource);
				node.addBinding(toTarget);
				node.addBinding(toSource);
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

		private function onElementEnd():void
		{
			_parserProduct = _parserProductStack.pop();

			var isNonTerminal:Boolean = getElementNode(_parserProduct).getAttributeCache(Attribute.TYPE) in _parser.templates;
			if (isNonTerminal) _parserProductStackNonTerminal.pop();
		}

		//
		// Linkage
		//
		/** Setup class which created for tag of type. */
		public function setLinkage(tag:String, type:Class):void { _linkage[tag] = type; }

		//
		// Library
		//
		/** Add resource (image, string, etc.) to global factory scope. */
		public function addResource(id:String, resource:*):void { _resources[id] = resource; }

		/** Add css to global factory scope. */
		public function addStyleSheet(css:String):void { _style.parse(css); }

		/** Define symbol as terminal (see TML specification) */
		public function addTerminal(symbol:String):void { _parser.terminals.push(symbol); }

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

			// Registry by tag for reusable templates
			var tag:String = xml.attribute(ATT_TAG);
			_parser.templates[tag] = template;
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