package starling.extensions.talon.utils
{
	import feathers.textures.Scale9Textures;

	import flash.utils.Dictionary;

	import starling.display.DisplayObject;
	import starling.display.DisplayObjectContainer;
	import starling.extensions.talon.core.Node;
	import starling.extensions.talon.core.StyleSheet;
	import starling.extensions.talon.display.ITalonComponent;
	import starling.extensions.talon.display.TalonComponentBase;
	import starling.extensions.talon.display.TalonLabel;

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

		private var _linkageByDefault:Class = TalonComponentBase;
		private var _linkage:Dictionary = new Dictionary();
		private var _prototypes:Dictionary = new Dictionary();
		private var _resources:Dictionary = new Dictionary();
		private var _style:StyleSheet = new StyleSheet();

		public function TalonFactory():void
		{
			setLinkage("label", TalonLabel);
		}

		public function build(id:String, includeStyleSheet:Boolean = true, includeResources:Boolean = true):DisplayObject
		{
			if (id == null) throw new ArgumentError("Parameter id must be non-null");
			var config:XML = _prototypes[id];
			if (config == null) throw new ArgumentError("Prototype by id: " + id + " not found");

			var element:DisplayObject = fromXML(config);
			if (element is ITalonComponent)
			{
				includeStyleSheet && ITalonComponent(element).node.setStyleSheet(_style);
				includeResources  && ITalonComponent(element).node.setResources(_resources);
			}

			return element;
		}


		private function fromXML(xml:XML):DisplayObject
		{
			var elementType:String = xml.name();
			var elementClass:Class = _linkage[elementType] || _linkageByDefault;
			var element:DisplayObject = new elementClass();

			if (element is ITalonComponent)
			{
				var node:Node = ITalonComponent(element).node;

				for each (var attribute:XML in xml.attributes())
				{
					var name:String = attribute.name();
					var value:String = attribute.valueOf();
					node.setAttribute(name, value);
				}

				node.setAttribute("type", elementType);
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
