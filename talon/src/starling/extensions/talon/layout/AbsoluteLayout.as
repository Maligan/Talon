package starling.extensions.talon.layout
{
	import starling.extensions.talon.core.Node;

	public class AbsoluteLayout extends Layout
	{
		public override function arrange(node:Node, width:Number, height:Number):void
		{
			// Node padding
			var paddingTop:Number = node.padding.top.toPixels(node.ppmm, node.ppem, node.pppt, height, 0, 0, width, height);
			var paddingRight:Number = node.padding.right.toPixels(node.ppmm, node.ppem, node.pppt, width, 0, 0, width, height);
			var paddingBottom:Number = node.padding.bottom.toPixels(node.ppmm, node.ppem, node.pppt, height, 0, 0, width, height);
			var paddingLeft:Number = node.padding.left.toPixels(node.ppmm, node.ppem, node.pppt, width, 0, 0, width, height);

			// Node origin
			var originX:Number = node.origin.x.toPixels(node.ppmm, node.ppem, node.pppt, width, 0, 0, width, height);
			var originY:Number = node.origin.x.toPixels(node.ppmm, node.ppem, node.pppt, height, 0, 0, width, height);

			for (var i:int = 0; i < node.numChildren; i++)
			{
				var child:Node = node.getChildAt(i);

				// Child margin
				var marginTop:Number = child.margin.top.toPixels(node.ppmm, node.ppem, node.pppt, height, 0, 0, width, height);
				var marginRight:Number = child.margin.right.toPixels(node.ppmm, node.ppem, node.pppt, width, 0, 0, width, height);
				var marginBottom:Number = child.margin.bottom.toPixels(node.ppmm, node.ppem, node.pppt, height, 0, 0, width, height);
				var marginLeft:Number = child.margin.left.toPixels(node.ppmm, node.ppem, node.pppt, width, 0, 0, width, height);

				with (child.anchor)
				{
					//
					// Horizontal (Width/X)
					//
					/**/ if ( left.isNone  &&  right.isNone)
					{
						child.bounds.width = child.width.toPixels(child.ppmm, child.ppem, node.pppt, width, 0, 0, width, height);
						child.bounds.x = originX;
						child.bounds.x += child.position.x.toPixels(child.ppmm, child.ppem, node.pppt, height, 0, 0, width, height);
						child.bounds.x -= child.pivot.x.toPixels(child.ppmm, child.ppem, child.pppt, child.bounds.height, 0, 0, width, height);
					}
					else if ( left.isNone  && !right.isNone)
					{
						child.bounds.right = paddingRight - marginRight + right.toPixels(child.ppmm, child.ppem, node.pppt, width, 0, 0, width, height);
						child.bounds.left = child.bounds.right - child.width.toPixels(child.ppmm, child.ppem, node.pppt, width, 0, 0, width, height);
					}
					else if (!left.isNone  &&  right.isNone)
					{
						child.bounds.left = paddingLeft + marginRight + left.toPixels(child.ppmm, child.ppem, node.pppt, width, 0, 0, width, height);
						child.bounds.right = child.bounds.left + child.width.toPixels(child.ppmm, child.ppem, node.pppt, width, 0, 0, width, height);
					}
					else if (!left.isNone  && !right.isNone)
					{
						child.bounds.left = paddingLeft + marginLeft + left.toPixels(child.ppmm, child.ppem, node.pppt, width, 0, 0, width, height);
						child.bounds.right = paddingRight - marginRight + right.toPixels(child.ppmm, child.ppem, node.pppt, width, 0, 0, width, height);
					}

					//
					// Vertical (Height/Y)
					//
					/**/ if ( top.isNone  &&  bottom.isNone)
					{
						child.bounds.height = child.height.toPixels(child.ppmm, child.ppem, node.pppt, height, 0, 0, width, height);
						child.bounds.y = originY;
						child.bounds.y += child.position.y.toPixels(child.ppmm, child.ppem, node.pppt, height, 0, 0, width, height);
						child.bounds.y -= child.pivot.y.toPixels(child.ppmm, child.ppem, child.pppt, child.bounds.height, 0, 0, width, height);
					}
					else if ( top.isNone  && !bottom.isNone)
					{
						child.bounds.bottom = paddingBottom - marginBottom + bottom.toPixels(child.ppmm, child.ppem, node.pppt, height, 0, 0, width, height);
						child.bounds.top = child.bounds.bottom - child.height.toPixels(child.ppmm, child.ppem, node.pppt, height, 0, 0, width, height);
					}
					else if (!top.isNone  &&  bottom.isNone)
					{
						child.bounds.top = paddingTop + marginTop + top.toPixels(child.ppmm, child.ppem, node.pppt, height, 0, 0, width, height);
						child.bounds.bottom = child.bounds.top + child.height.toPixels(child.ppmm, child.ppem, node.pppt, height, 0, 0, width, height);
					}
					else if (!top.isNone  && !bottom.isNone)
					{
						child.bounds.top = paddingTop + marginTop + top.toPixels(child.ppmm, child.ppem, node.pppt, height, 0, 0, width, height);
						child.bounds.bottom = paddingBottom - marginBottom + bottom.toPixels(child.ppmm, child.ppem, node.pppt, height, 0, 0, width, height);
					}
				}

				child.commit();
			}
		}
	}
}