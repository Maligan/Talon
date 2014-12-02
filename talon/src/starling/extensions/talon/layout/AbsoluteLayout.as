package starling.extensions.talon.layout
{
	import starling.extensions.talon.core.Node;

	public class AbsoluteLayout extends Layout
	{
		public override function arrange(node:Node, width:Number, height:Number):void
		{
			var paddingTop:Number = node.padding.top.toPixels(node.ppmm, node.ppem, node.pppt, height, 0, 0, width, height);
			var paddingRight:Number = node.padding.right.toPixels(node.ppmm, node.ppem, node.pppt, width, 0, 0, width, height);
			var paddingBottom:Number = node.padding.bottom.toPixels(node.ppmm, node.ppem, node.pppt, height, 0, 0, width, height);
			var paddingLeft:Number = node.padding.left.toPixels(node.ppmm, node.ppem, node.pppt, width, 0, 0, width, height);

			width -= paddingLeft + paddingRight;
			height -= paddingTop + paddingBottom;

			for (var i:int = 0; i < node.numChildren; i++)
			{
				var child:Node = node.getChildAt(i);

				with (child.anchor)
				{
					//
					// Height
					//
					/**/ if ( top.isAuto  &&  bottom.isAuto)
					{
						child.bounds.height = child.height.toPixels(child.ppmm, child.ppem, node.pppt, height, 0, 0, width, height);
						// TODO: child.x
					}
					else if ( top.isAuto  && !bottom.isAuto)
					{
						child.bounds.bottom = paddingBottom + bottom.toPixels(child.ppmm, child.ppem, node.pppt, height, 0, 0, width, height);
						child.bounds.top = child.bounds.bottom - child.height.toPixels(child.ppmm, child.ppem, node.pppt, height, 0, 0, width, height);
					}
					else if (!top.isAuto  &&  bottom.isAuto)
					{
						child.bounds.top = paddingTop + top.toPixels(child.ppmm, child.ppem, node.pppt, height, 0, 0, width, height);
						child.bounds.bottom = child.bounds.top + child.height.toPixels(child.ppmm, child.ppem, node.pppt, height, 0, 0, width, height);
					}
					else if (!top.isAuto  && !bottom.isAuto)
					{
						child.bounds.top = paddingTop + top.toPixels(child.ppmm, child.ppem, node.pppt, height, 0, 0, width, height);
						child.bounds.bottom = paddingBottom + bottom.toPixels(child.ppmm, child.ppem, node.pppt, height, 0, 0, width, height);
					}

					//
					// Width
					//
					/**/ if ( left.isAuto  &&  right.isAuto)
					{
						child.bounds.width = child.width.toPixels(child.ppmm, child.ppem, node.pppt, width, 0, 0, width, height);
						// TODO: child.x
					}
					else if ( left.isAuto  && !right.isAuto)
					{
						child.bounds.right = paddingRight + right.toPixels(child.ppmm, child.ppem, node.pppt, width, 0, 0, width, height);
						child.bounds.left = child.bounds.right - child.width.toPixels(child.ppmm, child.ppem, node.pppt, width, 0, 0, width, height);
					}
					else if (!left.isAuto  &&  right.isAuto)
					{
						child.bounds.left = paddingLeft + left.toPixels(child.ppmm, child.ppem, node.pppt, width, 0, 0, width, height);
						child.bounds.right = child.bounds.left + child.width.toPixels(child.ppmm, child.ppem, node.pppt, width, 0, 0, width, height);
					}
					else if (!left.isAuto  && !right.isAuto)
					{
						child.bounds.left = paddingLeft + left.toPixels(child.ppmm, child.ppem, node.pppt, width, 0, 0, width, height);
						child.bounds.right = paddingRight + right.toPixels(child.ppmm, child.ppem, node.pppt, width, 0, 0, width, height);
					}
				}

				child.commit();
			}
		}
	}
}