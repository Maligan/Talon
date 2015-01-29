package starling.extensions.talon.layout
{
	import starling.extensions.talon.core.Attribute;
	import starling.extensions.talon.core.Node;
	import starling.extensions.talon.utils.Visibility;

	public class AbsoluteLayout extends Layout
	{
		public override function arrange(node:Node, width:Number, height:Number):void
		{
			// Node padding
			var paddingTop:Number = node.padding.top.toPixelsSugar(node, height);
			var paddingRight:Number = node.padding.right.toPixelsSugar(node, width);
			var paddingBottom:Number = node.padding.bottom.toPixelsSugar(node, height);
			var paddingLeft:Number = node.padding.left.toPixelsSugar(node, width);

			// Node origin
			var originX:Number = node.origin.x.toPixelsSugar(node, width);
			var originY:Number = node.origin.x.toPixelsSugar(node, height);

			for (var i:int = 0; i < node.numChildren; i++)
			{
				var child:Node = node.getChildAt(i);
				if (child.getAttribute(Attribute.VISIBILITY) != Visibility.VISIBLE) continue;

				// Child margin
				var marginTop:Number = child.margin.top.toPixelsSugar(node, height);
				var marginRight:Number = child.margin.right.toPixelsSugar(node, width);
				var marginBottom:Number = child.margin.bottom.toPixelsSugar(node, height);
				var marginLeft:Number = child.margin.left.toPixelsSugar(node, width);

				with (child.anchor)
				{
					//
					// Horizontal (width/x/left/right)
					//
					/**/ if ( left.isNone &&  right.isNone)
					{
						child.bounds.width = child.width.toPixelsSugar(child, width, width, height, 0, 0, child.minWidth, child.maxWidth);
						child.bounds.x = originX;
						child.bounds.x += paddingLeft;
						child.bounds.x += child.position.x.toPixelsSugar(child, width);
						child.bounds.x -= child.pivot.x.toPixelsSugar(child, child.bounds.width);
					}
					else if ( left.isNone && !right.isNone)
					{
						child.bounds.right = paddingRight - marginRight + right.toPixelsSugar(child, width);
						child.bounds.left = child.bounds.right - child.width.toPixelsSugar(child, width, width, height, 0, 0, child.minWidth, child.maxWidth);
					}
					else if (!left.isNone &&  right.isNone)
					{
						child.bounds.left = paddingLeft + marginRight + left.toPixelsSugar(child, width);
						child.bounds.right = child.bounds.left + child.width.toPixelsSugar(child, width, width, height, 0, 0, child.minWidth, child.maxWidth);
					}
					else if (!left.isNone && !right.isNone)
					{
						var deltaWidth:Number = paddingLeft + marginLeft + paddingRight + marginRight;
						child.bounds.left = paddingLeft + marginLeft + left.toPixelsSugar(child, width - deltaWidth);
						child.bounds.right = paddingRight - marginRight + right.toPixelsSugar(child, width - deltaWidth);
					}

					//
					// Vertical (height/y/top/bottom)
					//
					/**/ if ( top.isNone &&  bottom.isNone)
					{
						child.bounds.height = child.height.toPixelsSugar(child, height, width, height, 0, 0, child.minHeight, child.maxHeight);
						child.bounds.y = originY;
						child.bounds.y += paddingTop;
						child.bounds.y += child.position.y.toPixelsSugar(child, height);
						child.bounds.y -= child.pivot.y.toPixelsSugar(child, child.bounds.height);
					}
					else if ( top.isNone && !bottom.isNone)
					{
						child.bounds.bottom = paddingBottom - marginBottom + bottom.toPixelsSugar(child, height);
						child.bounds.top = child.bounds.bottom - child.height.toPixelsSugar(child, height, width, height, 0, 0, child.minHeight, child.maxHeight);
					}
					else if (!top.isNone &&  bottom.isNone)
					{
						child.bounds.top = paddingTop + marginTop + top.toPixelsSugar(child, height);
						child.bounds.bottom = child.bounds.top + child.height.toPixelsSugar(child, height, width, height, 0, 0, child.minHeight, child.maxHeight);
					}
					else if (!top.isNone && !bottom.isNone)
					{
						var deltaHeight:Number = paddingTop + marginTop + paddingBottom + marginBottom;
						child.bounds.top = paddingTop + marginTop + top.toPixelsSugar(child, height - deltaHeight);
						child.bounds.bottom = paddingBottom - marginBottom + bottom.toPixelsSugar(child, height - deltaHeight);
					}
				}

				child.commit();
			}
		}

		public override function measureAutoWidth(node:Node, width:Number, height:Number):Number
		{
			var resultWidth:int = 0;

			for (var i:int = 0; i < node.numChildren; i++)
			{
				var child:Node = node.getChildAt(i);
				if (child.getAttribute(Attribute.VISIBILITY) == Visibility.COLLAPSED) continue;

				var childWidth:int = child.width.toPixelsSugar(child, width, width, height, 0, 0, child.minWidth, child.maxWidth);
				childWidth += child.margin.left.toPixelsSugar(child, width);
				childWidth += child.margin.right.toPixelsSugar(child, width);

				resultWidth = Math.max(resultWidth, childWidth);
			}

			return resultWidth + node.padding.right.toPixelsSugar(node, width) + node.padding.left.toPixelsSugar(node, width);
		}

		public override function measureAutoHeight(node:Node, width:Number, height:Number):Number
		{
			var resultHeight:int = 0;

			for (var i:int = 0; i < node.numChildren; i++)
			{
				var child:Node = node.getChildAt(i);
				if (child.getAttribute(Attribute.VISIBILITY) == Visibility.COLLAPSED) continue;

				var childHeight:int = child.height.toPixelsSugar(child, height, width, height, 0, 0, child.minHeight, child.maxHeight);
				childHeight += child.margin.top.toPixelsSugar(child, width);
				childHeight += child.margin.bottom.toPixelsSugar(child, width);

				resultHeight = Math.max(resultHeight, childHeight);
			}

			return resultHeight + node.padding.top.toPixelsSugar(node, height) + node.padding.bottom.toPixelsSugar(node, height);
		}
	}
}