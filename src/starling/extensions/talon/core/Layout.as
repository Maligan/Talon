package starling.extensions.talon.core
{
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;

	import starling.events.Event;
	import starling.extensions.talon.layout.CanvasLayoutStrategy;
	import starling.extensions.talon.layout.DockLayoutStrategy;
	import starling.extensions.talon.layout.LayoutStrategy;
	import starling.extensions.talon.layout.NoneLayoutStrategy;
	import starling.extensions.talon.layout.StackLayoutStrategy;
	import starling.extensions.talon.layout.WrapLayoutStrategy;

	public final class Layout
	{
		//
		// Static Registry & LayoutStrategy multitone
		//
		private static const _strategy:Dictionary = new Dictionary();
		private static const _strategySelfAttributes:Dictionary = new Dictionary();

		public static function registerLayout(alias:String, layout:LayoutStrategy, selfAttributes:Array = null, childAttributes:Array = null):void
		{
			var attributesDictionary:Dictionary = new Dictionary();
			for each (var attribute:String in selfAttributes) attributesDictionary[attribute] = true;

			_strategy[alias] = layout;
			_strategySelfAttributes[alias] = attributesDictionary;
		}

		// Defaults strategies
		registerLayout("none", new NoneLayoutStrategy());
		registerLayout("stack", new StackLayoutStrategy());
		registerLayout("dock", new DockLayoutStrategy());
		registerLayout("wrap", new WrapLayoutStrategy());
		registerLayout("canvas", new CanvasLayoutStrategy());

		//
		// Layout
		//
		private var _node:Node;
		private var _invalidated:Boolean;
		private var _bounds:Rectangle;

		public function Layout(node:Node)
		{
			_invalidated = true;
			_bounds = new Rectangle();
			_node = node;
			_node.addEventListener(Event.CHANGE, onBoxAttributeChanged);
		}

		private function onBoxAttributeChanged(e:Event):void
		{
			var property:String = String(e.data);
			if (propertyCausesInvalidation(property))
			{
				// invalidate();
			}
		}

		private function propertyCausesInvalidation(property:String):Boolean
		{
			// Change box layout attribute always cause invalidation
			if (property == "layout") return true;

			// If layout added with this self-attributes
			if (_strategySelfAttributes[_node.attributes.layout] && _strategySelfAttributes[_node.attributes.layout][property] === true) return true;

			// Otherwise do not invalidate
			return false;
		}

		public function commit():void
		{
			_node.dispatchEventWith(Event.RESIZE);
			arrange(bounds.width, bounds.height);
		}

		public function get bounds():Rectangle
		{
			return _bounds;
		}

		//
		// Delegate to current strategy
		//
		public function measureAutoWidth():int
		{
			return strategy.measureAutoHeight(_node, 1, 1);
		}

		public function measureAutoHeight():int
		{
			return strategy.measureAutoWidth(_node, 1, 1);
		}

		private function arrange(width:int, height:int):void
		{
			strategy.arrange(_node, width, height, 1, 1);
		}

		private function get strategy():LayoutStrategy
		{
			return _strategy[_node.attributes.layout];
		}
	}
}