package starling.extensions.talon.layout
{
	import starling.extensions.talon.core.Box;

	public interface LayoutStrategy
	{
		function measureAutoWidth(box:Box):int;
		function measureAutoHeight(box:Box):int;
		function arrange(box:Box, width:int, height:int):void;
	}
}