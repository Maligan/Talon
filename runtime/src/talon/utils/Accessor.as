package talon.utils
{
	import talon.Attribute;
	import talon.Node;

	[ExcludeClass]
	public class Accessor
	{
		public var width:Gauge;
		public var height:Gauge;

		public var minWidth:Gauge;
		public var minHeight:Gauge;

		public var maxWidth:Gauge;
		public var maxHeight:Gauge;

		public var marginTop:Gauge;
		public var marginRight:Gauge;
		public var marginBottom:Gauge;
		public var marginLeft:Gauge;

		public var paddingTop:Gauge;
		public var paddingRight:Gauge;
		public var paddingBottom:Gauge;
		public var paddingLeft:Gauge;

		public var anchorTop:Gauge;
		public var anchorRight:Gauge;
		public var anchorBottom:Gauge;
		public var anchorLeft:Gauge;

		public var x:Gauge;
		public var y:Gauge;

		public var originX:Gauge;
		public var originY:Gauge;

		public var pivotX:Gauge;
		public var pivotY:Gauge;

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

		private function gauge(name:String):Gauge
		{
			return new Gauge(_node.getOrCreateAttribute(name));
		}
	}
}
