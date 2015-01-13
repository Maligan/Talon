package starling.extensions.talon.layout
{
	import flash.utils.Dictionary;

	import starling.extensions.talon.core.Node;

	public class Layout
	{
		//
		// Static Layout Registry
		//
		public static const FLOW:String = "flow";
		public static const ABSOLUTE:String = "absolute";

		private static var _initialized:Boolean = false;
		private static var _layout:Dictionary = new Dictionary();
		private static var _layoutSelfAttributes:Dictionary = new Dictionary();
		private static var _layoutChildrenAttributes:Dictionary = new Dictionary();

		public static function registerLayoutAlias(aliasName:String, layout:Layout, selfAttributes:Array = null, childrenAttributes:Array = null):void
		{
			if (_layout[aliasName] != null) throw new ArgumentError("Layout alias " + aliasName + "already registered");

			_layout[aliasName] = layout;

			var helper:Dictionary;
			var attribute:String;

			helper = new Dictionary();
			for each (attribute in selfAttributes) helper[attribute] = true;
			_layoutSelfAttributes[aliasName] = helper;

			helper = new Dictionary();
			for each (attribute in childrenAttributes) helper[attribute] = true;
			_layoutChildrenAttributes[aliasName] = helper;
		}

		private static function initialize():void
		{
			if (_initialized == false)
			{
				_initialized = true;
				if (!_layout[FLOW]) registerLayoutAlias(FLOW, new FlowLayout(), null, ["width", "height"]);
				if (!_layout[ABSOLUTE]) registerLayoutAlias(ABSOLUTE, new AbsoluteLayout());
			}
		}

		public static function getLayoutByAlias(aliasName:String):Layout
		{
			initialize();
			return _layout[aliasName];
		}

		public static function isChildAttribute(aliasName:String, attributeName:String):Boolean
		{
			initialize();
			return _layoutChildrenAttributes[aliasName][attributeName];
		}

		//
		// Layout methods
		//
		/** This method will be call while arranging, and must calculate node width in pixels, based on node children. */
		public function measureAutoWidth(node:Node, width:Number, height:Number):Number
		{
			return 0;
		}

		/** This method will be call while arranging, and must calculate node height in pixels, based on node children. */
		public function measureAutoHeight(node:Node, width:Number, height:Number):Number
		{
			return 0;
		}

		/** Arrange (define bounds and commit) children within size. */
		public function arrange(node:Node, width:Number, height:Number):void
		{
			// NOP
		}
	}
}