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

		protected var _parser:TMLParser;
		protected var _parserProductStack:Array;
		protected var _parserProduct:*;

		protected var _linkageByDefault:Class;
		protected var _linkage:Dictionary = new Dictionary();
		protected var _resources:Object = new Dictionary();
		protected var _style:StyleSheet = new StyleSheet();

		public function TalonFactoryBase(linkageByDefault:Class):void
		{
			_linkageByDefault = linkageByDefault;
			_parser = new TMLParser(null, null, onElementBegin, onElementEnd);
			_parserProductStack = new Array();
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
			// Parse template, while parsing events dispatched (onElementBegin, onElementEnd)
			_parser.parseTemplate(id);
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
			var func:Array = StringUtil.parseFunction(value);
			if (func && func[0] == "bind")
			{
				var parent:ITalonElement = _parserProductStack[_parserProductStack.length - 1] as ITalonElement;
				var source:Attribute = parent.node.getOrCreateAttribute(func[1]);
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
		}

		//
		// Linkage
		//
		/** Setup class which created for symbol of type. */
		public function setLinkage(symbol:String, type:Class):void { _linkage[symbol] = type; }

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

			var id:String = xml.@id;
			if (id == null) throw new ArgumentError("Template must contains id attribute");

			if (xml.children().length() != 1) throw new ArgumentError("Template must contains one child");
			if (_parser.templates[id] != null) throw new ArgumentError("Template with id " + id + " already exists");

			_parser.templates[id] = xml.children()[0];
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
						throw new ArgumentError("Bad library content: " + subtype);
				}
			}
		}
	}
}