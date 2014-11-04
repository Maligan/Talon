package starling.extensions.talon.layout
{
	import starling.extensions.talon.core.Node;

	public class CanvasLayoutStrategy implements LayoutStrategy
	{
		public function CanvasLayoutStrategy()
		{
		}

		public function measureAutoWidth(node:Node, ppp:Number, pem:Number):Number
		{
			return 0;
		}

		public function measureAutoHeight(node:Node, ppp:Number, pem:Number):Number
		{
			return 0;
		}

		public function arrange(node:Node, ppp:Number, pem:Number, width:Number, height:Number):void
		{
		}
	}
}
