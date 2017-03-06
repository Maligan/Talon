package talon.layouts
{
	import talon.Node;
	import talon.utils.Gauge;

	public class AnchorLayout extends Layout
	{
		public override function measureWidth(node:Node, availableHeight:Number):Number
		{
			var maxChildWidth:Number = 0;

			for (var i:int = 0; i < node.numChildren; i++)
			{
				var child:Node = node.getChildAt(i);
				var childWidth:Number = child.left.toPixels(child)
									  + child.right.toPixels(child)
									  + calcSize(child, child.width, child.height, 0, 0, child.minWidth, child.maxWidth, 0);

				maxChildWidth = Math.max(maxChildWidth, childWidth);
			}

			return maxChildWidth
				 + node.paddingLeft.toPixels(node)
				 + node.paddingRight.toPixels(node);
		}

		public override function measureHeight(node:Node, availableWidth:Number):Number
		{
			var maxChildHeight:int = 0;

			for (var i:int = 0; i < node.numChildren; i++)
			{
				var child:Node = node.getChildAt(i);
				var childHeight:Number = child.top.toPixels(child)
					   		   		   + child.bottom.toPixels(child)
					   		   		   + calcSize(child, child.height, child.width, 0, 0, child.minHeight, child.maxHeight, 0);

				maxChildHeight = Math.max(maxChildHeight, childHeight);
			}

			return maxChildHeight
				 + node.paddingTop.toPixels(node)
				 + node.paddingBottom.toPixels(node);
		}

		public override function arrange(node:Node, width:Number, height:Number):void
		{
			var paddingLeft:Number = node.paddingLeft.toPixels(node, width);
			var paddingRight:Number = node.paddingRight.toPixels(node, width);
			var paddingTop:Number = node.paddingTop.toPixels(node, height);
			var paddingBottom:Number = node.paddingBottom.toPixels(node, height);

			var contentWidth:Number = width - paddingLeft - paddingRight;
			var contentHeight:Number = height - paddingTop - paddingBottom;

			for (var i:int = 0; i < node.numChildren; i++)
			{
				var child:Node = node.getChildAt(i);

				// x-axis
				if (isRespectingSize(child.left, child.right))
				{
					child.bounds.width = calcSize(child, child.width, child.height, contentWidth, contentHeight, child.minWidth, child.maxWidth, numStars(child.left) + numStars(child.width) + numStars(child.right));
					child.bounds.x = calcOffset(child, child.bounds.width, child.left, child.right, width, paddingLeft, paddingRight);
				}
				else
				{
					child.bounds.left = paddingLeft + child.left.toPixels(child, contentWidth);
					child.bounds.right = width - paddingRight - child.right.toPixels(child, contentWidth);
				}

				// y-axis
				if (isRespectingSize(child.top, child.bottom))
				{
					child.bounds.height = calcSize(child, child.height, child.width, contentHeight, contentWidth, child.minHeight, child.maxHeight, numStars(child.top) + numStars(child.height) + numStars(child.bottom));
					child.bounds.y = calcOffset(child, child.bounds.height, child.top, child.bottom, height, paddingTop, paddingBottom);
				}
				else
				{
					child.bounds.top = paddingTop + child.top.toPixels(child, contentHeight);
					child.bounds.bottom = height - paddingBottom - child.bottom.toPixels(child, contentHeight);
				}

				child.commit();
			}
		}

		private function isRespectingSize(left:Gauge, right:Gauge):Boolean
		{
			return left.isNone || left.unit == Gauge.STAR
				|| right.isNone || right.unit == Gauge.STAR;
		}

		private function numStars(gauge:Gauge):int
		{
			return gauge.unit == Gauge.STAR ? gauge.amount : 0;
		}

		private function calcOffset(child:Node, childWidth:Number, childLeft:Gauge, childRight:Gauge, parentWidth:Number, paddingLeft:Number, paddingRight:Number):Number
		{
			var contentWidth:Number = parentWidth - paddingLeft - paddingRight;

			var totalPx:Number =  contentWidth - childWidth;
			var totalStars:int = numStars(childLeft) + numStars(childRight);

			var leftPx:Number = childLeft.toPixels(child, childWidth, 0, totalPx, totalStars);
			var rightPx:Number = childRight.toPixels(child, contentWidth, 0, totalPx, totalStars);

			var align:Number;
			if (childLeft.isNone && !childRight.isNone) 		align = 1;
			else if (!childLeft.isNone && childRight.isNone)	align = 0;
			else												align = 0.5;

			return Layout.pad(parentWidth, childWidth, paddingLeft + leftPx, paddingRight + rightPx, align);
		}

		private function calcSize(child:Node, mainSize:Gauge, crossSize:Gauge, mainContentSize:Number, crossContentSize:Number, mainMinSize:Gauge, mainMaxSize:Gauge, totalStars:int):Number
		{
			var valueIsDependent:Boolean = mainSize.isNone && !crossSize.isNone;
			var valueAutoArg:Number = valueIsDependent ? crossSize.toPixels(child, crossContentSize) : Infinity;
			var value:Number = mainSize.toPixels(child, mainContentSize, valueAutoArg, mainContentSize, totalStars);

			if (!mainMinSize.isNone)
			{
				var min:Number = mainMinSize.toPixels(child, mainContentSize);
				if (min > value) return min;
			}

			if (!mainMaxSize.isNone)
			{
				var max:Number = mainMaxSize.toPixels(child, mainContentSize);
				if (max < value) return max;
			}

			return value;
		}
	}
}
