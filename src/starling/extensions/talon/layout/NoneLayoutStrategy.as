package starling.extensions.talon.layout
{
	import starling.extensions.talon.core.Node;

	public final class NoneLayoutStrategy implements LayoutStrategy
	{
		public function measureAutoWidth(node:Node, ppp:Number, pem:Number):Number
		{
			return 0;
		}

		public function measureAutoHeight(node:Node, ppp:Number, pem:Number):Number
		{
			return 0;
		}

		public function arrange(node:Node, width:Number, height:Number, ppp:Number, pem:Number):void
		{

		}
	}
}