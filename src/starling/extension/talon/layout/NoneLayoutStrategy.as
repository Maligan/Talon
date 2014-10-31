package starling.extension.talon.layout
{
	import starling.extension.talon.core.Box;

	public final class NoneLayoutStrategy implements LayoutStrategy
	{
		public function measureAutoWidth(box:Box):int
		{
			return 0;
		}

		public function measureAutoHeight(box:Box):int
		{
			return 0;
		}

		public function arrange(box:Box, width:int, height:int):void
		{

		}
	}
}