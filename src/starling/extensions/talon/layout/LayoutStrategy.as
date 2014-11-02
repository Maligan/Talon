package starling.extensions.talon.layout
{
	import starling.extensions.talon.core.Box;

	public interface LayoutStrategy
	{
		function measureAutoWidth(box:Box, ppp:Number, pem:Number):int
		function measureAutoHeight(box:Box, ppp:Number, pem:Number):int
		function arrange(box:Box, width:int, height:int, ppp:Number, pem:Number):void
	}
}