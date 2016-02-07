package talon.layout
{
	import talon.Attribute;
	import talon.Node;
	import talon.utils.AccessorGauge;
	import talon.utils.StringParseUtil;

	public class AbsoluteLayout extends Layout
	{
		public override function arrange(node:Node, width:Number, height:Number):void
		{
			// Node padding
			var paddingTop:Number = toPixelsSugar(node.accessor.paddingTop, node, height);
			var paddingRight:Number = toPixelsSugar(node.accessor.paddingRight, node, width);
			var paddingBottom:Number = toPixelsSugar(node.accessor.paddingBottom, node, height);
			var paddingLeft:Number = toPixelsSugar(node.accessor.paddingLeft, node, width);

			width -= paddingLeft + paddingRight;
			height -= paddingTop + paddingBottom;

			// Node origin
			var originX:Number = toPixelsSugar(node.accessor.originX, node, width);
			var originY:Number = toPixelsSugar(node.accessor.originY, node, height);

			for (var i:int = 0; i < node.numChildren; i++)
			{
				var child:Node = node.getChildAt(i);
				if (!StringParseUtil.parseBoolean(child.getAttributeCache(Attribute.VISIBLE))) continue;

				// Child margin
				var marginTop:Number = toPixelsSugar(child.accessor.marginTop, node, height);
				var marginRight:Number = toPixelsSugar(child.accessor.marginRight, node, width);
				var marginBottom:Number = toPixelsSugar(child.accessor.marginBottom, node, height);
				var marginLeft:Number = toPixelsSugar(child.accessor.marginLeft, node, width);

				//
				// Horizontal (width/x/left/right)
				//
				/**/ if ( child.accessor.anchorLeft.isNone &&  child.accessor.anchorRight.isNone)
				{
					child.bounds.width = toPixelsSugar(child.accessor.width, child, width, width, height, 0, 0, child.accessor.minWidth, child.accessor.maxWidth);
					child.bounds.x = originX;
					child.bounds.x += paddingLeft;
					child.bounds.x += toPixelsSugar(child.accessor.x, child, width);
					child.bounds.x -= toPixelsSugar(child.accessor.pivotX, child, child.bounds.width);
				}
				else if ( child.accessor.anchorLeft.isNone && !child.accessor.anchorRight.isNone)
				{
					child.bounds.right = paddingRight - marginRight + toPixelsSugar(child.accessor.anchorRight, child, width);
					child.bounds.left = child.bounds.right - toPixelsSugar(child.accessor.width, child, width, width, height, 0, 0, child.accessor.minWidth, child.accessor.maxWidth);
				}
				else if (!child.accessor.anchorLeft.isNone &&  child.accessor.anchorRight.isNone)
				{
					child.bounds.left = paddingLeft + marginRight + toPixelsSugar(child.accessor.anchorLeft, child, width);
					child.bounds.right = child.bounds.left + toPixelsSugar(child.accessor.width, child, width, width, height, 0, 0, child.accessor.minWidth, child.accessor.maxWidth);
				}
				else if (!child.accessor.anchorLeft.isNone && !child.accessor.anchorRight.isNone)
				{
					var deltaWidth:Number = paddingLeft + marginLeft + paddingRight + marginRight;
					child.bounds.left = paddingLeft + marginLeft + toPixelsSugar(child.accessor.anchorLeft, child, width - deltaWidth);
					child.bounds.right = paddingRight - marginRight + toPixelsSugar(child.accessor.anchorRight, child, width - deltaWidth);
				}

				//
				// Vertical (height/y/top/bottom)
				//
				/**/ if ( child.accessor.anchorTop.isNone &&  child.accessor.anchorBottom.isNone)
				{
					child.bounds.height = toPixelsSugar(child.accessor.height, child, height, width, height, 0, 0, child.accessor.minHeight, child.accessor.maxHeight);
					child.bounds.y = originY;
					child.bounds.y += paddingTop;
					child.bounds.y += toPixelsSugar(child.accessor.y, child, height);
					child.bounds.y -= toPixelsSugar(child.accessor.pivotY, child, child.bounds.height);
				}
				else if ( child.accessor.anchorTop.isNone && !child.accessor.anchorBottom.isNone)
				{
					child.bounds.bottom = paddingBottom - marginBottom + toPixelsSugar(child.accessor.anchorBottom, child, height);
					child.bounds.top = child.bounds.bottom - toPixelsSugar(child.accessor.height, child, height, width, height, 0, 0, child.accessor.minHeight, child.accessor.maxHeight);
				}
				else if (!child.accessor.anchorTop.isNone &&  child.accessor.anchorBottom.isNone)
				{
					child.bounds.top = paddingTop + marginTop + toPixelsSugar(child.accessor.anchorTop, child, height);
					child.bounds.bottom = child.bounds.top + toPixelsSugar(child.accessor.height, child, height, width, height, 0, 0, child.accessor.minHeight, child.accessor.maxHeight);
				}
				else if (!child.accessor.anchorTop.isNone && !child.accessor.anchorBottom.isNone)
				{
					var deltaHeight:Number = paddingTop + marginTop + paddingBottom + marginBottom;
					child.bounds.top = paddingTop + marginTop + toPixelsSugar(child.accessor.anchorTop, child, height - deltaHeight);
					child.bounds.bottom = paddingBottom - marginBottom + toPixelsSugar(child.accessor.anchorBottom, child, height - deltaHeight);
				}

				child.commit();
			}
		}

		public override function measureAutoWidth(node:Node, availableHeight:Number):Number
		{
			var resultWidth:int = 0;

			for (var i:int = 0; i < node.numChildren; i++)
			{
				var child:Node = node.getChildAt(i);
				if (!StringParseUtil.parseBoolean(child.getAttributeCache(Attribute.VISIBLE))) continue;

				var childWidth:int = toPixelsSugar(child.accessor.width, child, 0, Infinity, availableHeight, 0, 0, child.accessor.minWidth, child.accessor.maxWidth);
				childWidth += toPixelsSugar(child.accessor.marginLeft, child);
				childWidth += toPixelsSugar(child.accessor.marginRight, child);

				resultWidth = Math.max(resultWidth, childWidth);
			}

			return resultWidth + toPixelsSugar(node.accessor.paddingRight, node) + toPixelsSugar(node.accessor.paddingLeft, node);
		}

		public override function measureAutoHeight(node:Node, availableWidth:Number):Number
		{
			var resultHeight:int = 0;

			for (var i:int = 0; i < node.numChildren; i++)
			{
				var child:Node = node.getChildAt(i);
				if (!StringParseUtil.parseBoolean(child.getAttributeCache(Attribute.VISIBLE))) continue;

				var childHeight:int = toPixelsSugar(child.accessor.height, child, 0, availableWidth, Infinity, 0, 0, child.accessor.minHeight, child.accessor.maxHeight);
				childHeight += toPixelsSugar(child.accessor.marginTop, child);
				childHeight += toPixelsSugar(child.accessor.marginBottom, child);

				resultHeight = Math.max(resultHeight, childHeight);
			}

			return resultHeight + toPixelsSugar(node.accessor.paddingTop, node) + toPixelsSugar(node.accessor.paddingBottom, node);
		}

		/**
		 * @private
		 * Method toPixels() with optimized signature for most common use cases.
		 * @param context ppmm, ppem, ppdp used from thi node.
		 * @param min value bottom restrainer
		 * @param max value top restrainer
		 */
		protected final function toPixelsSugar(gauge:AccessorGauge, context:Node, pp100p:Number = 0, aw:Number = 0, ah:Number = 0, ppts:Number = 0, ts:int = 0, min:AccessorGauge = null, max:AccessorGauge = null):Number
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
