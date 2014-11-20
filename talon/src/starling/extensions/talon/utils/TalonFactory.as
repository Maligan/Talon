package starling.extensions.talon.utils
{
	import flash.utils.Dictionary;

	import starling.display.DisplayObject;
	import starling.display.DisplayObjectContainer;
	import starling.extensions.talon.core.Node;
	import starling.extensions.talon.core.StyleSheet;
	import starling.extensions.talon.display.ITalonTarget;
	import starling.extensions.talon.display.TalonSprite;
	import starling.extensions.talon.display.TalonTextField;

	public final class TalonFactory
	{
		public static function fromXML(library:XML):TalonFactory
		{
			var factory:TalonFactory = new TalonFactory();

			for each (var item:XML in library.*)
			{
				switch (item.name().toString())
				{
					case "stylesheet":
						factory.addLibraryStyleSheet(item.valueOf());
						break;
					case "prototype":
						factory.addLibraryPrototype(item.@id, item.*[0]);
						break;
				}
			}

			return factory;
		}

		private var _linkageByDefault:Class;
		private var _linkage:Dictionary = new Dictionary();
		private var _prototypes:Dictionary = new Dictionary();
		private var _resources:Dictionary = new Dictionary();
		private var _style:StyleSheet = new StyleSheet();

		public function TalonFactory(defaultLinkageClass:Class = null):void
		{
			_linkageByDefault = defaultLinkageClass || TalonSprite;
			setLinkage("node", TalonSprite);
			setLinkage("label", TalonTextField);
		}

		public function build(id:String, includeStyleSheet:Boolean = true, includeResources:Boolean = true):DisplayObject
		{
			if (id == null) throw new ArgumentError("Parameter id must be non-null");
			var config:XML = _prototypes[id];
			if (config == null) throw new ArgumentError("Prototype by id: " + id + " not found");

			var element:DisplayObject = fromXML(config);
			if (element is ITalonTarget)
			{
				includeResources && ITalonTarget(element).node.setResources(_resources);
				includeStyleSheet && ITalonTarget(element).node.setStyleSheet(_style);
			}

			return element;
		}

		private function fromXML(xml:XML):DisplayObject
		{
			var elementType:String = xml.name();
			var elementClass:Class = _linkage[elementType] || _linkageByDefault;
			var element:DisplayObject = new elementClass();

			if (element is ITalonTarget)
			{
				var node:Node = ITalonTarget(element).node;
				node.setAttribute("type", elementType);

				for each (var attribute:XML in xml.attributes())
				{
					var name:String = attribute.name();
					var value:String = attribute.valueOf();
					node.setAttribute(name, value);
				}
			}

			if (element is DisplayObjectContainer)
			{
				var container:DisplayObjectContainer = DisplayObjectContainer(element);
				for each (var childXML:XML in xml.children())
				{
					var childElement:DisplayObject = fromXML(childXML);
					container.addChild(childElement);
				}
			}

			return element;
		}


		//
		// Linkage
		//
		public function setLinkage(type:String, displayObjectClass:Class):void
		{
			_linkage[type] = displayObjectClass;
		}

		//
		// Library
		//
		public function hasPrototype(id:String):Boolean
		{
			return _prototypes[id] != null;
		}

		public function addLibraryPrototype(id:String, xml:XML):void
		{
			_prototypes[id] = xml;
		}

		public function addLibraryResource(id:String, resource:*):void
		{
			_resources[id] = resource;
		}

		public function addLibraryStyleSheet(css:String):void
		{
			_style.parse(css);
		}
	}
}
