package starling.extensions.talon.layout
{
	import starling.extensions.talon.core.Node;

	public interface LayoutStrategy
	{
		function measureAutoWidth(node:Node, ppp:Number, pem:Number):Number
		function measureAutoHeight(node:Node, ppp:Number, pem:Number):Number
		function arrange(node:Node, width:Number, height:Number, ppp:Number, pem:Number):void
	}
}