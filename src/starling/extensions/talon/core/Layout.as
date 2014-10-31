package starling.extensions.talon.core
{
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;

	import starling.events.Event;
	import starling.extensions.talon.layout.LayoutStrategy;

	public final class Layout
	{
		//
		// Static Registry
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

		//
		// Layout
		//
		private var _box:Box;
		private var _invalidated:Boolean;
		private var _bounds:Rectangle;

		public function Layout(box:Box)
		{
			_box = box;
			_box.addEventListener(Event.CHANGE, onBoxAttributeChanged);
		}

		private function onBoxAttributeChanged(e:Event):void
		{
			var property:String = String(e.data);
			if (propertyCausesInvalidation(property))
			{
				invalidate();
			}
		}

		private function propertyCausesInvalidation(property:String):Boolean
		{
			// Change box layout attribute always cause invalidate
			if (property == "layout") return true;

			// If layout added with this self-attributes
			if (_strategySelfAttributes[_box.attributes.layout][property] === true) return true;

			// Otherwise do not invalidate
			return false;
		}

		private function invalidate():void
		{
			_invalidated = true;
		}

		private function validate():void
		{
			if (_invalidated)
			{
				_invalidated = false;
				// method.arrange();
			}
		}

		public function get bounds():Rectangle
		{
			return _bounds;
		}
	}
}