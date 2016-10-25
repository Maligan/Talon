package talon.layout
{
	import talon.Node;

	public class GridLayout extends Layout
	{
		public override function measureWidth(node:Node, availableHeight:Number):Number
		{
			throw new Error("Not implemented");
		}

		public override function measureHeight(node:Node, availableWidth:Number):Number
		{
			throw new Error("Not implemented");
		}

		public override function arrange(node:Node, width:Number, height:Number):void
		{
			throw new Error("Not implemented");
		}
	}
}
