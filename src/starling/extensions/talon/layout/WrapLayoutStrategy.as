package starling.extensions.talon.layout
{
	import starling.extensions.talon.core.Node;

	public class WrapLayoutStrategy implements LayoutStrategy
	{
		public function WrapLayoutStrategy()
		{
		}

		public function measureAutoWidth(node:Node, ppp:Number, pem:Number):int
		{
			return 0;
		}

		public function measureAutoHeight(node:Node, ppp:Number, pem:Number):int
		{
			return 0;
		}

		public function arrange(node:Node, width:int, height:int, ppp:Number, pem:Number):void
		{
		}
	}
}
