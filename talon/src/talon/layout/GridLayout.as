package talon.layout
{
	import talon.Node;

	public class GridLayout extends Layout
	{
		public override function measureAutoWidth(node:Node, availableHeight:Number):Number
		{
			throw new Error("Not implemented");
		}

		public override function measureAutoHeight(node:Node, availableWidth:Number):Number
		{
			throw new Error("Not implemented");
		}

		public override function arrange(node:Node, width:Number, height:Number):void
		{
			throw new Error("Not implemented");
		}
	}
}
