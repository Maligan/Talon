package starling.extensions.talon.layout
{
	import flash.utils.Dictionary;

	import starling.extensions.talon.core.Gauge;

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
		private static var _observableAttributes:Dictionary = new Dictionary();
		private static var _observableChildrenAttributes:Dictionary = new Dictionary();

		public static function registerLayoutAlias(aliasName:String, layout:Layout, observableAttributes:Array = null, observableChildrenAttributes:Array = null):void
		{
			if (_layout[aliasName] != null) throw new ArgumentError("Layout alias " + aliasName + "already registered");

			_layout[aliasName] = layout;

			var helper:Dictionary;
			var attribute:String;

			helper = new Dictionary();
			for each (attribute in observableAttributes) helper[attribute] = true;
			_observableAttributes[aliasName] = helper;

			helper = new Dictionary();
			for each (attribute in observableChildrenAttributes) helper[attribute] = true;
			_observableChildrenAttributes[aliasName] = helper;
		}

		/** Get layout strategy by it's name. */
		public static function getLayoutByAlias(aliasName:String):Layout
		{
			initialize();
			return _layout[aliasName];
		}

		/** Layout must be invalidated if node attribute changed. */
		public static function isObservableAttribute(layout:String, attributeName:String):Boolean
		{
			initialize();
			return _observableAttributes[layout][attributeName];
		}

		/** Layout must be invalidated if node child attribute changed. */
		public static function isObservableChildrenAttribute(layout:String, attributeName:String):Boolean
		{
			initialize();
			return _observableChildrenAttributes[layout][attributeName];
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

		//
		// Utility function
		//
		/**
		 * @private
		 * Method toPixels() with optimized signature for most common use cases.
		 * @param context ppmm, ppem, pppt used from thi node.
		 * @param min value bottom restrainer
		 * @param max value top restrainer
		 */
		public function toPixelsSugar(gauge:Gauge, context:Node, pp100p:Number = 0, width:Number = 0, height:Number = 0, ppts:Number = 0, ts:int = 0, min:Gauge = null, max:Gauge = null):Number
		{
			var value:Number = gauge.toPixels(context.ppmm, context.ppem, context.pppt, pp100p, width, height, ppts, ts);

			if (min && !min.isNone)
			{
				var minValue:Number = min.toPixels(context.ppmm, context.ppem, context.pppt, pp100p, width, height, ppts, ts);
				if (minValue > value) value = minValue;
			}

			if (max && !max.isNone)
			{
				var maxValue:Number = max.toPixels(context.ppmm, context.ppem, context.pppt, pp100p, width, height, ppts, ts);
				if (maxValue < value) value = maxValue;
			}

			return value;
		}
	}
}