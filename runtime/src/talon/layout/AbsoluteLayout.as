package talon.layout
{
	import talon.Attribute;
	import talon.Node;
	import talon.utils.AttributeGauge;
	import talon.utils.ParseUtil;

	public class AbsoluteLayout extends Layout
	{
		public override function arrange(node:Node, width:Number, height:Number):void
		{
			// Node padding
			var paddingTop:Number = toPixelsSugar(node.paddingTop, node, height);
			var paddingRight:Number = toPixelsSugar(node.paddingRight, node, width);
			var paddingBottom:Number = toPixelsSugar(node.paddingBottom, node, height);
			var paddingLeft:Number = toPixelsSugar(node.paddingLeft, node, width);

			width -= paddingLeft + paddingRight;
			height -= paddingTop + paddingBottom;

			// Node origin
			var originX:Number = toPixelsSugar(node.originX, node, width);
			var originY:Number = toPixelsSugar(node.originY, node, height);

			for (var i:int = 0; i < node.numChildren; i++)
			{
				var child:Node = node.getChildAt(i);
				if (!ParseUtil.parseBoolean(child.getAttributeCache(Attribute.VISIBLE))) continue;

				// Child margin
				var marginTop:Number = toPixelsSugar(child.marginTop, node, height);
				var marginRight:Number = toPixelsSugar(child.marginRight, node, width);
				var marginBottom:Number = toPixelsSugar(child.marginBottom, node, height);
				var marginLeft:Number = toPixelsSugar(child.marginLeft, node, width);

				//
				// Horizontal (width/x/left/right)
				//
				/**/ if ( child.anchorLeft.isNone &&  child.anchorRight.isNone)
				{
					child.bounds.width = toPixelsSugar(child.width, child, width, width, height, 0, 0, child.minWidth, child.maxWidth);
					child.bounds.x = originX;
					child.bounds.x += paddingLeft;
					child.bounds.x += toPixelsSugar(child.x, child, width);
					child.bounds.x -= toPixelsSugar(child.pivotX, child, child.bounds.width);
				}
				else if ( child.anchorLeft.isNone && !child.anchorRight.isNone)
				{
					child.bounds.right = paddingRight - marginRight + toPixelsSugar(child.anchorRight, child, width);
					child.bounds.left = child.bounds.right - toPixelsSugar(child.width, child, width, width, height, 0, 0, child.minWidth, child.maxWidth);
				}
				else if (!child.anchorLeft.isNone &&  child.anchorRight.isNone)
				{
					child.bounds.left = paddingLeft + marginRight + toPixelsSugar(child.anchorLeft, child, width);
					child.bounds.right = child.bounds.left + toPixelsSugar(child.width, child, width, width, height, 0, 0, child.minWidth, child.maxWidth);
				}
				else if (!child.anchorLeft.isNone && !child.anchorRight.isNone)
				{
					var deltaWidth:Number = paddingLeft + marginLeft + paddingRight + marginRight;
					child.bounds.left = paddingLeft + marginLeft + toPixelsSugar(child.anchorLeft, child, width - deltaWidth);
					child.bounds.right = paddingRight - marginRight + toPixelsSugar(child.anchorRight, child, width - deltaWidth);
				}

				//
				// Vertical (height/y/top/bottom)
				//
				/**/ if ( child.anchorTop.isNone &&  child.anchorBottom.isNone)
				{
					child.bounds.height = toPixelsSugar(child.height, child, height, width, height, 0, 0, child.minHeight, child.maxHeight);
					child.bounds.y = originY;
					child.bounds.y += paddingTop;
					child.bounds.y += toPixelsSugar(child.y, child, height);
					child.bounds.y -= toPixelsSugar(child.pivotY, child, child.bounds.height);
				}
				else if ( child.anchorTop.isNone && !child.anchorBottom.isNone)
				{
					child.bounds.bottom = paddingBottom - marginBottom + toPixelsSugar(child.anchorBottom, child, height);
					child.bounds.top = child.bounds.bottom - toPixelsSugar(child.height, child, height, width, height, 0, 0, child.minHeight, child.maxHeight);
				}
				else if (!child.anchorTop.isNone &&  child.anchorBottom.isNone)
				{
					child.bounds.top = paddingTop + marginTop + toPixelsSugar(child.anchorTop, child, height);
					child.bounds.bottom = child.bounds.top + toPixelsSugar(child.height, child, height, width, height, 0, 0, child.minHeight, child.maxHeight);
				}
				else if (!child.anchorTop.isNone && !child.anchorBottom.isNone)
				{
					var deltaHeight:Number = paddingTop + marginTop + paddingBottom + marginBottom;
					child.bounds.top = paddingTop + marginTop + toPixelsSugar(child.anchorTop, child, height - deltaHeight);
					child.bounds.bottom = paddingBottom - marginBottom + toPixelsSugar(child.anchorBottom, child, height - deltaHeight);
				}

				child.commit();
			}
		}

		public override function measureWidth(node:Node, availableHeight:Number):Number
		{
			var resultWidth:int = 0;

			for (var i:int = 0; i < node.numChildren; i++)
			{
				var child:Node = node.getChildAt(i);
				if (!ParseUtil.parseBoolean(child.getAttributeCache(Attribute.VISIBLE))) continue;

				var childWidth:int = toPixelsSugar(child.width, child, 0, Infinity, availableHeight, 0, 0, child.minWidth, child.maxWidth);
				childWidth += toPixelsSugar(child.marginLeft, child);
				childWidth += toPixelsSugar(child.marginRight, child);

				resultWidth = Math.max(resultWidth, childWidth);
			}

			return resultWidth + toPixelsSugar(node.paddingRight, node) + toPixelsSugar(node.paddingLeft, node);
		}

		public override function measureHeight(node:Node, availableWidth:Number):Number
		{
			var resultHeight:int = 0;

			for (var i:int = 0; i < node.numChildren; i++)
			{
				var child:Node = node.getChildAt(i);
				if (!ParseUtil.parseBoolean(child.getAttributeCache(Attribute.VISIBLE))) continue;

				var childHeight:int = toPixelsSugar(child.height, child, 0, availableWidth, Infinity, 0, 0, child.minHeight, child.maxHeight);
				childHeight += toPixelsSugar(child.marginTop, child);
				childHeight += toPixelsSugar(child.marginBottom, child);

				resultHeight = Math.max(resultHeight, childHeight);
			}

			return resultHeight + toPixelsSugar(node.paddingTop, node) + toPixelsSugar(node.paddingBottom, node);
		}

		/**
		 * @private
		 * Method toPixels() with optimized signature for most common use cases.
		 * @param context ppmm, ppem, ppdp used from thi node.
		 * @param min value bottom restrainer
		 * @param max value top restrainer
		 */
		protected final function toPixelsSugar(gauge:AttributeGauge, context:Node, pp100p:Number = 0, aw:Number = 0, ah:Number = 0, ppts:Number = 0, ts:int = 0, min:AttributeGauge = null, max:AttributeGauge = null):Number
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
