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
					   + calcSize(child, child.width, child.height, 0, 0, child.minWidth, child.maxWidth);
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
					+ calcSize(child, child.height, child.width, 0, 0, child.minHeight, child.maxHeight);
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
					child.bounds.width = calcSize(child, child.width, child.height, contentWidth, contentHeight, child.minWidth, child.maxWidth);
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
					child.bounds.height = calcSize(child, child.height, child.width, contentHeight, contentWidth, child.maxHeight, child.maxHeight);
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

		private function calcOffset(child:Node, childWidth:Number, childLeft:AttributeGauge, childRight:AttributeGauge, parentWidth:Number, paddingLeft:Number, paddingRight:Number):Number
		{
			var contentWidth:Number = parentWidth - paddingLeft - paddingRight;

			var leftNone:Boolean = childLeft.isNone;
			var leftStar:Boolean = childLeft.unit == AttributeGauge.STAR;
			var leftRest:Boolean = !leftNone && !leftStar;

			var rightNone:Boolean = childRight.isNone;
			var rightStar:Boolean = childRight.unit == AttributeGauge.STAR;
			var rightRest:Boolean = !rightNone && !rightStar;

			// There are 8 (from 9 possible) cases:
			/**/ if (leftNone && rightNone)
				return Layout.pad(parentWidth, childWidth, paddingLeft, paddingRight, 0.5);
			else if (leftNone && rightStar)
				return Layout.pad(parentWidth, childWidth, paddingLeft, paddingRight, 0);
			else if (leftNone && rightRest)
				return Layout.pad(parentWidth, childWidth, paddingLeft, paddingRight + childRight.toPixels(child.ppmm, child.ppem, child.ppdp, contentWidth), 1);
			else if (leftStar && rightNone)
				return Layout.pad(parentWidth, childWidth, paddingLeft, paddingRight, 1);
			else if (leftStar && rightStar)
			{
				var totalPx:Number = contentWidth - childWidth;
				var total:Number = childLeft.amount + childRight.amount;
				return Layout.pad(parentWidth, childWidth, totalPx * (childLeft.amount/total), totalPx * (childRight.amount/total), childLeft.amount/childRight.amount);
			}
			else if (leftStar && rightRest)
				return Layout.pad(parentWidth, childWidth, paddingLeft, paddingRight + childRight.toPixels(child.ppmm, child.ppem, child.ppdp, contentWidth), 1);
			else if (leftRest && rightNone)
				return Layout.pad(parentWidth, childWidth, paddingLeft + childLeft.toPixels(child.ppmm, child.ppem, child.ppdp, contentWidth), paddingRight, 0);
			else if (leftRest && rightStar)
				return Layout.pad(parentWidth, childWidth, paddingLeft + childLeft.toPixels(child.ppmm, child.ppem, child.ppdp, contentWidth), paddingRight, 0);

			// There is an assertion - last one (leftRest && rightRest) must be handled outside this method
			throw new Error();
		}

		private function calcSize(child:Node, mS:AttributeGauge, cS:AttributeGauge, mCS:Number, cCS:Number, mMin:AttributeGauge, mMax:AttributeGauge):Number
		{
			// FIXME: What about stars? (yes, size can be in stars)
			// FIXME: mCS can be Infinity (set to zero?)

			// [Calculate]
			var value:Number = 0;

			/**/ if (!mS.isNone)
				value = mS.toPixels(child.ppmm, child.ppem, child.ppdp, mCS);
			else if (!cS.isNone)
				value = mS.toPixels(child.ppmm, child.ppem, child.ppdp, mCS, cS.toPixels(child.ppmm, child.ppem, child.ppdp, cCS));
			else
				value = mS.toPixels(child.ppmm, child.ppem, child.ppdp, mCS, Infinity);

			// [Restrain]
			if (!mMin.isNone)
			{
				var min:Number = mMin.toPixels(child.ppmm, child.ppem, child.ppdp, mCS);
				if (min > value) return min;
			}

			if (!mMax.isNone)
			{
				var max:Number = mMax.toPixels(child.ppem, child.ppem, child.ppdp, mCS);
				if (max < value) return max;
			}

			// [Result]
			return value;
		}
	}
}