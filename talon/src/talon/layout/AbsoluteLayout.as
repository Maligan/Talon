package talon.layout
{
	import talon.Attribute;
	import talon.Node;
	import talon.utils.Gauge;
	import talon.utils.StringUtil;

	public class AbsoluteLayout extends Layout
	{
		public override function arrange(node:Node, width:Number, height:Number):void
		{
			// Node padding
			var paddingTop:Number = toPixelsSugar(node.padding.top, node, height);
			var paddingRight:Number = toPixelsSugar(node.padding.right, node, width);
			var paddingBottom:Number = toPixelsSugar(node.padding.bottom, node, height);
			var paddingLeft:Number = toPixelsSugar(node.padding.left, node, width);

			width -= paddingLeft + paddingRight;
			height -= paddingTop + paddingBottom;

			// Node origin
			var originX:Number = toPixelsSugar(node.origin.x, node, width);
			var originY:Number = toPixelsSugar(node.origin.x, node, height);

			for (var i:int = 0; i < node.numChildren; i++)
			{
				var child:Node = node.getChildAt(i);
				if (!StringUtil.parseBoolean(child.getAttributeCache(Attribute.VISIBLE))) continue;

				// Child margin
				var marginTop:Number = toPixelsSugar(child.margin.top, node, height);
				var marginRight:Number = toPixelsSugar(child.margin.right, node, width);
				var marginBottom:Number = toPixelsSugar(child.margin.bottom, node, height);
				var marginLeft:Number = toPixelsSugar(child.margin.left, node, width);

				with (child.anchor)
				{
					//
					// Horizontal (width/x/left/right)
					//
					/**/ if ( left.isNone &&  right.isNone)
					{
						child.bounds.width = toPixelsSugar(child.width, child, width, width, height, 0, 0, child.minWidth, child.maxWidth);
						child.bounds.x = originX;
						child.bounds.x += paddingLeft;
						child.bounds.x += toPixelsSugar(child.position.x, child, width);
						child.bounds.x -= toPixelsSugar(child.pivot.x, child, child.bounds.width);
					}
					else if ( left.isNone && !right.isNone)
					{
						child.bounds.right = paddingRight - marginRight + toPixelsSugar(right, child, width);
						child.bounds.left = child.bounds.right - toPixelsSugar(child.width, child, width, width, height, 0, 0, child.minWidth, child.maxWidth);
					}
					else if (!left.isNone &&  right.isNone)
					{
						child.bounds.left = paddingLeft + marginRight + toPixelsSugar(left, child, width);
						child.bounds.right = child.bounds.left + toPixelsSugar(child.width, child, width, width, height, 0, 0, child.minWidth, child.maxWidth);
					}
					else if (!left.isNone && !right.isNone)
					{
						var deltaWidth:Number = paddingLeft + marginLeft + paddingRight + marginRight;
						child.bounds.left = paddingLeft + marginLeft + toPixelsSugar(left, child, width - deltaWidth);
						child.bounds.right = paddingRight - marginRight + toPixelsSugar(right, child, width - deltaWidth);
					}

					//
					// Vertical (height/y/top/bottom)
					//
					/**/ if ( top.isNone &&  bottom.isNone)
					{
						child.bounds.height = toPixelsSugar(child.height, child, height, width, height, 0, 0, child.minHeight, child.maxHeight);
						child.bounds.y = originY;
						child.bounds.y += paddingTop;
						child.bounds.y += toPixelsSugar(child.position.y, child, height);
						child.bounds.y -= toPixelsSugar(child.pivot.y, child, child.bounds.height);
					}
					else if ( top.isNone && !bottom.isNone)
					{
						child.bounds.bottom = paddingBottom - marginBottom + toPixelsSugar(bottom, child, height);
						child.bounds.top = child.bounds.bottom - toPixelsSugar(child.height, child, height, width, height, 0, 0, child.minHeight, child.maxHeight);
					}
					else if (!top.isNone &&  bottom.isNone)
					{
						child.bounds.top = paddingTop + marginTop + toPixelsSugar(top, child, height);
						child.bounds.bottom = child.bounds.top + toPixelsSugar(child.height, child, height, width, height, 0, 0, child.minHeight, child.maxHeight);
					}
					else if (!top.isNone && !bottom.isNone)
					{
						var deltaHeight:Number = paddingTop + marginTop + paddingBottom + marginBottom;
						child.bounds.top = paddingTop + marginTop + toPixelsSugar(top, child, height - deltaHeight);
						child.bounds.bottom = paddingBottom - marginBottom + toPixelsSugar(bottom, child, height - deltaHeight);
					}
				}

				child.validate();
			}
		}

		public override function measureAutoWidth(node:Node, availableHeight:Number):Number
		{
			var resultWidth:int = 0;

			for (var i:int = 0; i < node.numChildren; i++)
			{
				var child:Node = node.getChildAt(i);
				if (!StringUtil.parseBoolean(child.getAttributeCache(Attribute.VISIBLE))) continue;

				var childWidth:int = toPixelsSugar(child.width, child, 0, Infinity, availableHeight, 0, 0, child.minWidth, child.maxWidth);
				childWidth += toPixelsSugar(child.margin.left, child);
				childWidth += toPixelsSugar(child.margin.right, child);

				resultWidth = Math.max(resultWidth, childWidth);
			}

			return resultWidth + toPixelsSugar(node.padding.right, node) + toPixelsSugar(node.padding.left, node);
		}

		public override function measureAutoHeight(node:Node, availableWidth:Number):Number
		{
			var resultHeight:int = 0;

			for (var i:int = 0; i < node.numChildren; i++)
			{
				var child:Node = node.getChildAt(i);
				if (!StringUtil.parseBoolean(child.getAttributeCache(Attribute.VISIBLE))) continue;

				var childHeight:int = toPixelsSugar(child.height, child, 0, availableWidth, Infinity, 0, 0, child.minHeight, child.maxHeight);
				childHeight += toPixelsSugar(child.margin.top, child);
				childHeight += toPixelsSugar(child.margin.bottom, child);

				resultHeight = Math.max(resultHeight, childHeight);
			}

			return resultHeight + toPixelsSugar(node.padding.top, node) + toPixelsSugar(node.padding.bottom, node);
		}

		/**
		 * @private
		 * Method toPixels() with optimized signature for most common use cases.
		 * @param context ppmm, ppem, ppdp used from thi node.
		 * @param min value bottom restrainer
		 * @param max value top restrainer
		 */
		protected final function toPixelsSugar(gauge:Gauge, context:Node, pp100p:Number = 0, aw:Number = 0, ah:Number = 0, ppts:Number = 0, ts:int = 0, min:Gauge = null, max:Gauge = null):Number
		{
			aw = Infinity;
			ah = Infinity;
			var value:Number = gauge.toPixels(context.ppmm, context.ppem, context.ppdp, pp100p, aw, ppts, ts);

			if (min && !min.isNone)
			{
				var minValue:Number = min.toPixels(context.ppmm, context.ppem, context.ppdp, pp100p, aw, ppts, ts);
				if (minValue > value) value = minValue;
			}

			if (max && !max.isNone)
			{
				var maxValue:Number = max.toPixels(context.ppmm, context.ppem, context.ppdp, pp100p, aw, ppts, ts);
				if (maxValue < value) value = maxValue;
			}

			return value;
		}
	}
}
