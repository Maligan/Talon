package starling.extensions.talon.layout
{
	import starling.extensions.talon.core.Node;

	public interface LayoutStrategy
	{
		function measureAutoWidth(node:Node, ppp:Number, pem:Number):int
		function measureAutoHeight(node:Node, ppp:Number, pem:Number):int
		function arrange(node:Node, width:int, height:int, ppp:Number, pem:Number):void
	}
}