package talon.layouts
{
	import talon.core.Attribute;
	import talon.core.Node;
	import talon.utils.Gauge;
	import talon.utils.ParseUtil;

	/** @private */
	public class AnchorLayout extends Layout
	{
		public override function measureWidth(node:Node, availableHeight:Number):Number
		{
			var maxChildWidth:Number = 0;

			for (var i:int = 0; i < node.numChildren; i++)
			{
				var child:Node = node.getChildAt(i);
				if (isVisible(child))
				{
					var childWidth:Number = child.left.toPixels()
										  + child.right.toPixels()
										  + calcSize(child, child.width, child.height, 0, 0, child.minWidth, child.maxWidth, 0);
	
					maxChildWidth = Math.max(maxChildWidth, childWidth);
				}
			}

			return maxChildWidth
				 + node.paddingLeft.toPixels()
				 + node.paddingRight.toPixels();
		}

		public override function measureHeight(node:Node, availableWidth:Number):Number
		{
			var maxChildHeight:int = 0;

			for (var i:int = 0; i < node.numChildren; i++)
			{
				var child:Node = node.getChildAt(i);
				if (isVisible(child))
				{
					var childHeight:Number = child.top.toPixels()
										   + child.bottom.toPixels()
										   + calcSize(child, child.height, child.width, 0, 0, child.minHeight, child.maxHeight, 0);
	
					maxChildHeight = Math.max(maxChildHeight, childHeight);
				}
			}

			return maxChildHeight
				 + node.paddingTop.toPixels()
				 + node.paddingBottom.toPixels();
		}

		public override function arrange(node:Node, width:Number, height:Number):void
		{
			var paddingLeft:Number = node.paddingLeft.toPixels(width);
			var paddingRight:Number = node.paddingRight.toPixels(width);
			var paddingTop:Number = node.paddingTop.toPixels(height);
			var paddingBottom:Number = node.paddingBottom.toPixels(height);

			var contentWidth:Number = width - paddingLeft - paddingRight;
			var contentHeight:Number = height - paddingTop - paddingBottom;

			for (var i:int = 0; i < node.numChildren; i++)
			{
				var child:Node = node.getChildAt(i);
				if (!isVisible(child)) continue;

				// x-axis
				if (isRespectingSize(child.left, child.right))
				{
					child.bounds.width = calcSize(child, child.width, child.height, contentWidth, contentHeight, child.minWidth, child.maxWidth, numStars(child.left) + numStars(child.width) + numStars(child.right));
					child.bounds.x = calcOffset(child, child.bounds.width, child.left, child.right, width, paddingLeft, paddingRight);
				}
				else
				{
					child.bounds.left = paddingLeft + child.left.toPixels(contentWidth);
					child.bounds.right = width - paddingRight - child.right.toPixels(contentWidth);
				}

				// y-axis
				if (isRespectingSize(child.top, child.bottom))
				{
					child.bounds.height = calcSize(child, child.height, child.width, contentHeight, contentWidth, child.minHeight, child.maxHeight, numStars(child.top) + numStars(child.height) + numStars(child.bottom));
					child.bounds.y = calcOffset(child, child.bounds.height, child.top, child.bottom, height, paddingTop, paddingBottom);
				}
				else
				{
					child.bounds.top = paddingTop + child.top.toPixels(contentHeight);
					child.bounds.bottom = height - paddingBottom - child.bottom.toPixels(contentHeight);
				}
			}
		}

		private function isRespectingSize(left:Gauge, right:Gauge):Boolean
		{
			return left.isNone  || left.unit  == Gauge.STAR
				|| right.isNone || right.unit == Gauge.STAR;
		}
		
		private function isVisible(node:Node):Boolean
		{
			return ParseUtil.parseBoolean(
				node.getAttributeCache(Attribute.VISIBLE)
			)
		}

		private function numStars(gauge:Gauge):int
		{
			return gauge.unit == Gauge.STAR ? gauge.amount : 0;
		}

		private function calcOffset(child:Node, childWidth:Number, childLeft:Gauge, childRight:Gauge, parentWidth:Number, paddingLeft:Number, paddingRight:Number):Number
		{
			var contentWidth:Number = parentWidth - paddingLeft - paddingRight;

			var totalPx:Number = contentWidth - childWidth;
			var totalStars:int = numStars(childLeft) + numStars(childRight);

			var leftPx:Number = childLeft.toPixels(childWidth, 0, totalPx / totalStars);
			var rightPx:Number = childRight.toPixels(contentWidth, 0, totalPx / totalStars);

			var align:Number;
			if (childLeft.isNone && !childRight.isNone) 		align = 1;
			else if (!childLeft.isNone && childRight.isNone)	align = 0;
			else												align = 0.5;

			return Layout.pad(parentWidth, childWidth, paddingLeft + leftPx, paddingRight + rightPx, align);
		}

		private function calcSize(child:Node, childMainSize:Gauge, childCrossSize:Gauge, contentMainSize:Number, contentCrossSize:Number, childMainMinSize:Gauge, childMainMaxSize:Gauge, totalStars:int):Number
		{
			var valueIsDependent:Boolean = childMainSize.isNone && !childCrossSize.isNone;
			var valueAutoArg:Number = valueIsDependent ? childCrossSize.toPixels(contentCrossSize) : Infinity;
			var value:Number = childMainSize.toPixels(contentMainSize, valueAutoArg, contentMainSize / totalStars);

			if (!childMainMinSize.isNone)
			{
				var min:Number = childMainMinSize.toPixels(contentMainSize);
				if (min > value) return min;
			}

			if (!childMainMaxSize.isNone)
			{
				var max:Number = childMainMaxSize.toPixels(contentMainSize);
				if (max < value) return max;
			}

			return value;
		}
	}
}
