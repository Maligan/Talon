package starling.extensions.talon.layout
{
	import flash.utils.Dictionary;

	import starling.extensions.talon.core.Node;

	public class Layout
	{
		//
		// Static Registry & Layout multitone
		//
		public static const NONE:String = "none";
		public static const FLOW:String = "flow";

		private static var _initialized:Boolean = false;
		private static var _layout:Dictionary = new Dictionary();
		private static var _layoutSelfAttributes:Dictionary = new Dictionary();

		public static function registerLayoutAlias(aliasName:String, layout:Layout, selfAttributes:Array = null, childAttributes:Array = null):void
		{
			var attributesDictionary:Dictionary = new Dictionary();
			for each (var attribute:String in selfAttributes) attributesDictionary[attribute] = true;

			_layout[aliasName] = layout;
			_layoutSelfAttributes[aliasName] = attributesDictionary;
		}

		public static function getLayoutByAlias(aliasName:String):Layout
		{
			if (_initialized == false)
			{
				_initialized = true;
				registerLayoutAlias(NONE, new Layout());
				registerLayoutAlias(FLOW, new FlowLayout());
			}

			return _layout[aliasName];
		}

		//
		// Layout methods
		//
		public function measureAutoWidth(node:Node):Number
		{
			return 0;
		}

		public function measureAutoHeight(node:Node):Number
		{
			return 0;
		}

		public function arrange(node:Node, width:Number, height:Number):void
		{
			// NOP
		}
	}
}