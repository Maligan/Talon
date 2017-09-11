package talon.layouts
{
	import flash.utils.Dictionary;

	import talon.core.Attribute;
	import talon.core.Node;

	/** @private */
	public class Layout
	{
		//
		// Static Layout Registry
		//
		public static const FLOW:String = "flow";
		public static const ANCHOR:String = "anchor";

		private static const COMMON:Array = [
			// Width
			Attribute.MIN_WIDTH,
			Attribute.WIDTH,
			Attribute.MAX_WIDTH,
			// Height
			Attribute.HEIGHT,
			Attribute.MIN_HEIGHT,
			Attribute.MAX_HEIGHT,
			// Misc
			Attribute.VISIBLE,
			Attribute.FILTER
		];
		
		private static var _layouts:Dictionary;

		public static function registerLayout(name:String, layout:Layout):void
		{
			initialize();
			_layouts[name] = layout;
		}

		/** Get layout strategy by it's name. */
		public static function getLayout(name:String):Layout
		{
			initialize();
			return _layouts[name];
		}

		private static function initialize():void
		{
			if (_layouts == null)
			{
				_layouts = new Dictionary();
				registerLayout(ANCHOR, new AnchorLayout());
				registerLayout(FLOW, new FlowLayout()); // ["gap", "interline", "wrap", "orientation"]
			}
		}

		//
		// Useful layout methods
		//
		public static function pad(parentSize:Number, childSize:Number, paddingBefore:Number, paddingAfter:Number, k:Number):Number
		{
			// NB! k in [0; 1]
			return paddingBefore + (parentSize - paddingBefore - childSize - paddingAfter) * k;
		}

		//
		// Layout methods
		//
		/** This method will be call while arranging, and must calculate node width in pixels, based on node children. */
		public function measureWidth(node:Node, availableHeight:Number):Number { throw new Error("Method not implemented"); }

		/** This method will be call while arranging, and must calculate node height in pixels, based on node children. */
		public function measureHeight(node:Node, availableWidth:Number):Number { throw new Error("Method not implemented"); }

		/** Arrange (define bounds and commit) children within size. */
		public function arrange(node:Node, width:Number, height:Number):void { throw new Error("Method not implemented"); }

		/** Change of attribute must invoke node invalidation. */
		public function isObservable(node:Node, attribute:Attribute):Boolean
		{
			if (attribute.node == node)
				return attribute.name == Attribute.PADDING
					|| attribute.name == Attribute.VISIBLE;
			
			else if (attribute.node.parent == node)
				return COMMON.indexOf(attribute.name) != -1;
			
			return false;
		}
	}
}