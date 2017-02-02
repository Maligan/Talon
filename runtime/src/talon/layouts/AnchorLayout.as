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
					   + restrain(child, child.width, child.minWidth, child.maxWidth, 0, availableHeight);
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
					+ restrain(child, child.width, child.minWidth, child.maxWidth, 0, availableWidth);
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
				if (respect(child.left, child.right))
				{
					child.bounds.width = restrain(child, child.width, child.minWidth, child.maxWidth, contentWidth, contentWidth);
					child.bounds.x = calculate(child, child.bounds.width, child.left, child.right, width, paddingLeft, paddingRight);
				}
				else
				{
					child.bounds.left = paddingLeft + child.left.toPixels(child.ppmm, child.ppem, child.ppdp, contentWidth);
					child.bounds.right = width - paddingRight - child.right.toPixels(child.ppmm, child.ppem, child.ppdp, contentWidth);
				}

				// y-axis
				if (respect(child.top, child.bottom))
				{
					child.bounds.height = restrain(child, child.height, child.minHeight, child.maxHeight, contentHeight, contentHeight);
					child.bounds.y = calculate(child, child.bounds.height, child.top, child.bottom, height, paddingTop, paddingBottom);
				}
				else
				{
					child.bounds.top = paddingTop + child.top.toPixels(child.ppmm, child.ppem, child.ppdp, contentHeight);
					child.bounds.bottom = height - paddingBottom - child.bottom.toPixels(child.ppmm, child.ppem, child.ppdp, contentHeight);
				}

				child.commit();
			}
		}

		private function respect(left:AttributeGauge, right:AttributeGauge):Boolean
		{
			return left.isNone || left.unit == AttributeGauge.STAR
				|| right.isNone || right.unit == AttributeGauge.STAR;
		}

		private function calculate(child:Node, childWidth:Number, childLeft:AttributeGauge, childRight:AttributeGauge, parentWidth:Number, paddingLeft:Number, paddingRight:Number):Number
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

			// Last one - (leftRest && rightRest) must be handled outside this method
			throw new Error();
		}

		private function restrain(n:Node, val:AttributeGauge, min:AttributeGauge, max:AttributeGauge, pp100p:Number, aa:Number):Number
		{
			var valPx:Number = val.toPixels(n.ppmm, n.ppem, n.ppdp, pp100p, aa);
			var minPx:Number = min.toPixels(n.ppmm, n.ppem, n.ppdp);
			var maxPx:Number = max.toPixels(n.ppmm, n.ppem, n.ppdp);

			if (!min.isNone && valPx < minPx) return minPx;
			if (!max.isNone && valPx > maxPx) return maxPx;
			return valPx;
		}
	}
}