package talon.utils
{
	import talon.Attribute;
	import talon.Node;

	[ExcludeClass]
	public class Accessor
	{
		/** @private */ public var width:AttributeGauge;
		/** @private */ public var height:AttributeGauge;

		/** @private */ public var minWidth:AttributeGauge;
		/** @private */ public var minHeight:AttributeGauge;

		/** @private */ public var maxWidth:AttributeGauge;
		/** @private */ public var maxHeight:AttributeGauge;

		/** @private */ public var marginTop:AttributeGauge;
		/** @private */ public var marginRight:AttributeGauge;
		/** @private */ public var marginBottom:AttributeGauge;
		/** @private */ public var marginLeft:AttributeGauge;

		/** @private */ public var paddingTop:AttributeGauge;
		/** @private */ public var paddingRight:AttributeGauge;
		/** @private */ public var paddingBottom:AttributeGauge;
		/** @private */ public var paddingLeft:AttributeGauge;

		/** @private */ public var anchorTop:AttributeGauge;
		/** @private */ public var anchorRight:AttributeGauge;
		/** @private */ public var anchorBottom:AttributeGauge;
		/** @private */ public var anchorLeft:AttributeGauge;

		/** @private */ public var x:AttributeGauge;
		/** @private */ public var y:AttributeGauge;

		/** @private */ public var originX:AttributeGauge;
		/** @private */ public var originY:AttributeGauge;

		/** @private */ public var pivotX:AttributeGauge;
		/** @private */ public var pivotY:AttributeGauge;

		/** @private */ public var classes:AttributeStringSet;
		/** @private */ public var states:AttributeStringSet;

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

			classes = new AttributeStringSet(_node, Attribute.CLASS);
			states = new AttributeStringSet(_node, Attribute.STATE);
		}

		private function gauge(name:String):AttributeGauge
		{
			return new AttributeGauge(_node.getOrCreateAttribute(name));
		}
	}
}
