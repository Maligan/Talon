package talon.utils
{
	import talon.Attribute;
	import talon.Node;

	[ExcludeClass]
	public class Accessor
	{
		public var width:AccessorGauge;
		public var height:AccessorGauge;

		public var minWidth:AccessorGauge;
		public var minHeight:AccessorGauge;

		public var maxWidth:AccessorGauge;
		public var maxHeight:AccessorGauge;

		public var marginTop:AccessorGauge;
		public var marginRight:AccessorGauge;
		public var marginBottom:AccessorGauge;
		public var marginLeft:AccessorGauge;

		public var paddingTop:AccessorGauge;
		public var paddingRight:AccessorGauge;
		public var paddingBottom:AccessorGauge;
		public var paddingLeft:AccessorGauge;

		public var anchorTop:AccessorGauge;
		public var anchorRight:AccessorGauge;
		public var anchorBottom:AccessorGauge;
		public var anchorLeft:AccessorGauge;

		public var x:AccessorGauge;
		public var y:AccessorGauge;

		public var originX:AccessorGauge;
		public var originY:AccessorGauge;

		public var pivotX:AccessorGauge;
		public var pivotY:AccessorGauge;

		public var classes:AccessorStringSet;
		public var states:AccessorStringSet;


		private var _node:Node;

		public function Accessor(node:Node)
		{
			_node = node;

			width = gauge(Attribute.WIDTH);
			height = gauge(Attribute.HEIGHT);

			minWidth = gauge(Attribute.MIN_WIDTH);
			minHeight = gauge(Attribute.MIN_HEIGHT);

			maxWidth = gauge(Attribute.MAX_WIDTH);
			maxHeight = gauge(Attribute.MAX_HEIGHT);

			marginTop = gauge(Attribute.MARGIN_TOP);
			marginRight = gauge(Attribute.MARGIN_RIGHT);
			marginBottom = gauge(Attribute.MARGIN_BOTTOM);
			marginLeft = gauge(Attribute.MARGIN_LEFT);

			paddingTop = gauge(Attribute.PADDING_TOP);
			paddingRight = gauge(Attribute.PADDING_RIGHT);
			paddingBottom = gauge(Attribute.PADDING_BOTTOM);
			paddingLeft = gauge(Attribute.PADDING_LEFT);

			anchorTop = gauge(Attribute.ANCHOR_TOP);
			anchorRight = gauge(Attribute.ANCHOR_RIGHT);
			anchorBottom = gauge(Attribute.ANCHOR_BOTTOM);
			anchorLeft = gauge(Attribute.ANCHOR_LEFT);

			x = gauge(Attribute.X);
			y = gauge(Attribute.Y);

			pivotX = gauge(Attribute.PIVOT_X);
			pivotY = gauge(Attribute.PIVOT_Y);

			originX = gauge("originX");
			originY = gauge("originY");

			classes = new AccessorStringSet(_node.getOrCreateAttribute(Attribute.CLASS));
			states = new AccessorStringSet(_node.getOrCreateAttribute(Attribute.STATE));
		}

		private function gauge(name:String):AccessorGauge
		{
			return new AccessorGauge(_node.getOrCreateAttribute(name));
		}
	}
}
