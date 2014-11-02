package starling.extensions.talon.layout
{
	import starling.extensions.talon.core.Box;

	public class DockLayoutStrategy implements LayoutStrategy
	{
		public function DockLayoutStrategy()
		{
		}

		public function measureAutoWidth(box:Box, ppp:Number, pem:Number):int
		{
			return 0;
		}

		public function measureAutoHeight(box:Box, ppp:Number, pem:Number):int
		{
			return 0;
		}

		public function arrange(box:Box, width:int, height:int, ppp:Number, pem:Number):void
		{
		}
	}
}
