package talon.layouts
{
	import talon.Node;
	import talon.utils.AttributeGauge;

	public class AnchorLayout extends Layout
	{
		public override function measureWidth(node:Node, availableHeight:Number):Number
		{
			var width:Number = 0;

			width += node.paddingLeft.toPixels(node.ppmm, node.ppem, node.ppdp)
				   + node.paddingRight.toPixels(node.ppmm, node.ppem, node.ppdp);

			for each (var child:Node in node)
			{
				width += child.left.toPixels(child.ppmm, child.ppem, child.ppdp)
					   + child.right.toPixels(child.ppmm, child.ppem, child.ppdp)
					   + calcSize(child, child.width, child.height, 0, 0, child.minWidth, child.maxWidth, 0);
			}

			return width;
		}

		public override function measureHeight(node:Node, availableWidth:Number):Number
		{
			var height:Number = 0;

			height += node.paddingTop.toPixels(node.ppmm, node.ppem, node.ppdp)
					+ node.paddingBottom.toPixels(node.ppmm, node.ppem, node.ppdp);

			for each (var child:Node in node)
			{
				height += child.top.toPixels(child.ppmm, child.ppem, child.ppdp)
					+ child.bottom.toPixels(child.ppmm, child.ppem, child.ppdp)
					+ calcSize(child, child.height, child.width, 0, 0, child.minHeight, child.maxHeight, 0);
			}

			return height;
		}

		public override function arrange(node:Node, width:Number, height:Number):void
		{
			var paddingLeft:Number = node.paddingLeft.toPixels(node.ppmm, node.ppem, node.ppdp, width);
			var paddingRight:Number = node.paddingRight.toPixels(node.ppmm, node.ppem, node.ppdp, width);
			var paddingTop:Number = node.paddingTop.toPixels(node.ppmm, node.ppem, node.ppdp, height);
			var paddingBottom:Number = node.paddingBottom.toPixels(node.ppmm, node.ppem, node.ppdp, height);

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
					child.bounds.left = paddingLeft + child.left.toPixels(child.ppmm, child.ppem, child.ppdp, contentWidth);
					child.bounds.right = width - paddingRight - child.right.toPixels(child.ppmm, child.ppem, child.ppdp, contentWidth);
				}

				// y-axis
				if (isRespectingSize(child.top, child.bottom))
				{
					child.bounds.height = calcSize(child, child.height, child.width, contentHeight, contentWidth, child.minHeight, child.maxHeight, numStars(child.top) + numStars(child.height) + numStars(child.bottom));
					child.bounds.y = calcOffset(child, child.bounds.height, child.top, child.bottom, height, paddingTop, paddingBottom);
				}
				else
				{
					child.bounds.top = paddingTop + child.top.toPixels(child.ppmm, child.ppem, child.ppdp, contentHeight);
					child.bounds.bottom = height - paddingBottom - child.bottom.toPixels(child.ppmm, child.ppem, child.ppdp, contentHeight);
				}

				child.commit();
			}
		}

		private function isRespectingSize(left:AttributeGauge, right:AttributeGauge):Boolean
		{
			return left.isNone || left.unit == AttributeGauge.STAR
				|| right.isNone || right.unit == AttributeGauge.STAR;
		}

		private function numStars(gauge:AttributeGauge):int
		{
			return gauge.unit == AttributeGauge.STAR ? gauge.amount : 0;
		}

		private function calcOffset(child:Node, childWidth:Number, childLeft:AttributeGauge, childRight:AttributeGauge, parentWidth:Number, paddingLeft:Number, paddingRight:Number):Number
		{
			var contentWidth:Number = parentWidth - paddingLeft - paddingRight;

			var totalPx:Number =  contentWidth - childWidth;
			var totalStars:int = numStars(childLeft) + numStars(childRight);

			var leftPx:Number = childLeft.toPixels(child.ppem, child.ppem, child.ppdp, childWidth, 0, totalPx, totalStars);
			var rightPx:Number = childRight.toPixels(child.ppmm, child.ppem, child.ppdp, contentWidth, 0, totalPx, totalStars);

			var align:Number;
			if (childLeft.isNone && !childRight.isNone) 		align = 1;
			else if (!childLeft.isNone && childRight.isNone)	align = 0;
			else												align = 0.5;

			return Layout.pad(parentWidth, childWidth, paddingLeft + leftPx, paddingRight + rightPx, align);
		}

		private function calcSize(child:Node, mainSize:AttributeGauge, crossSize:AttributeGauge, mainContentSize:Number, crossContentSize:Number, mainMinSize:AttributeGauge, mainMaxSize:AttributeGauge, totalStars:int):Number
		{
			var valueIsDependent:Boolean = mainSize.isNone && !crossSize.isNone;
			var valueAutoArg:Number = valueIsDependent ? crossSize.toPixels(child.ppmm, child.ppem, child.ppdp, crossContentSize) : Infinity;
			var value:Number = mainSize.toPixels(child.ppmm, child.ppem, child.ppdp, mainContentSize, valueAutoArg, mainContentSize, totalStars);

			if (!mainMinSize.isNone)
			{
				var min:Number = mainMinSize.toPixels(child.ppmm, child.ppem, child.ppdp, mainContentSize);
				if (min > value) return min;
			}

			if (!mainMaxSize.isNone)
			{
				var max:Number = mainMaxSize.toPixels(child.ppem, child.ppem, child.ppdp, mainContentSize);
				if (max < value) return max;
			}

			return value;
		}
	}
}