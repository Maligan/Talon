package starling.extensions.talon.layout
{
	import starling.extensions.talon.core.Gauge;
	import starling.extensions.talon.core.Node;
	import starling.extensions.talon.utils.Orientation;

	public class FlowLayout extends Layout
	{
		private static const DEFAULT_GAP:String = Gauge.AUTO;
		private static const DEFAULT_ORIENTATION:String = Orientation.VERTICAL;

		private static const gauge:Gauge = new Gauge();

		public override function arrange(node:Node, ppp:Number, pem:Number, width:Number, height:Number):void
		{
			// Layout properties
			var orientation:String = node.getAttribute("orientation") || DEFAULT_ORIENTATION;

			gauge.parse(node.getAttribute("gap") || DEFAULT_GAP);
			var gap:Number = gauge.toPixels(ppp, pem, (orientation == Orientation.HORIZONTAL) ? node.bounds.width : node.bounds.height, 0);
			width -= node.padding.left.toPixels(ppp, pem, width, 0) + node.padding.right.toPixels(ppp, pem, width, 0);
			height -= node.padding.top.toPixels(ppp, pem, height, 0) + node.padding.bottom.toPixels(ppp, pem, height, 0);

			//
			// Horizontal
			//
			if (orientation == Orientation.HORIZONTAL)
			{
				arrangeSide1("width",  "x",  "measureAutoWidth",  width, gap, ppp, pem, node);
				arrangeSide2("height", "y", "measureAutoHeight", height, gap, ppp, pem, node);
			}
			else if (orientation == Orientation.VERTICAL)
			{
				arrangeSide1("height", "y", "measureAutoHeight", height, gap, ppp, pem, node);
				arrangeSide2("width",  "x", "measureAutoWidth",  width,  gap, ppp, pem, node);
			}

			//
			// Arrange children
			//
			var sumHeight:Number = node.numChildren > 1 ? (node.numChildren - 1) * gap : 0;
			var sumWidth:Number = node.numChildren > 1 ? (node.numChildren - 1) * gap : 0;

			for (var i:int = 0; i < node.numChildren; i++)
			{
				var child:Node = node.getChildAt(i);
				sumHeight += child.bounds.height;
				sumWidth += child.bounds.width;
			}
			var deltaX:Number = (orientation == Orientation.HORIZONTAL) ? (width - sumWidth) : 0;
			var deltaY:Number = (orientation == Orientation.VERTICAL) ? (height - sumHeight) : 0;

			var halign:String = node.getAttribute("halign");
			var valign:String = node.getAttribute("valign");
			deltaX = halign == "right" ? deltaX : halign == "center" ? deltaX/2 : 0;
			deltaY = valign == "bottom" ? deltaY : valign == "center" ? deltaY/2 : 0;

			// Padding
			deltaX += node.padding.left.toPixels(ppp, pem, height, 0);
			deltaY += node.padding.top.toPixels(ppp, pem, height, 0);

			for (var i:int = 0; i < node.numChildren; i++)
			{
				var child:Node = node.getChildAt(i);

				var dY:Number = 0;
				var dX:Number = 0;

				if (orientation == Orientation.VERTICAL)
				{
					dX = halign == "right" ? (width - child.bounds.width) : halign == "center" ? (width - child.bounds.width)/2 : 0;
				}

				if (orientation == Orientation.HORIZONTAL)
				{
					dY = valign == "bottom" ? (height - child.bounds.height) : valign == "center" ? (height - child.bounds.height)/2 : 0;
				}

				child.bounds.x += deltaX + dX;
				child.bounds.y += deltaY + dY;
				child.commit();
			}
		}

		private function arrangeSide2(name:String, asix:String, auto:String, value:int, gap:int, ppp:Number, pem:Number, node:Node):void
		{
			for (var i:int = 0; i < node.numChildren; i++)
			{
				var child:Node = node.getChildAt(i);
				child.bounds[name] = child[name].toPixels(ppp, pem, value, 0);
				child.bounds[asix] = 0;
			}
		}

		private function arrangeSide1(name:String, asix:String, auto:String, value:int, gap:int, ppp:Number, pem:Number, node:Node):void
		{
			var i:int;
			var child:Node;

			var starCount:int = 0;
			var starTarget:int = value - (node.numChildren > 1 ? (node.numChildren - 1) * gap : 0);

			for (i = 0; i < node.numChildren; i++)
			{
				child = node.getChildAt(i);
				if (child[name].unit == Gauge.STAR)
				{
					starCount += child[name].amount;
				}
				else
				{
					child.bounds[name] = child[name].toPixels(ppp, pem, value, 0);
					starTarget -= child.bounds[name];
				}
			}

			for (i = 0; i < node.numChildren; i++)
			{
				child = node.getChildAt(i);
				if (child[name].unit == Gauge.STAR)
				{
					child.bounds[name] = child[name].toPixels(ppp, pem, starTarget, starCount);
				}
			}

			var shift:int = 0;
			for (i = 0; i < node.numChildren; i++)
			{
				child = node.getChildAt(i);
				child.bounds[asix] = shift;
				shift += child.bounds[name] + gap;
			}
		}

		public override function measureAutoWidth(node:Node, ppp:Number, pem:Number):Number
		{
			var result:Number = 0;
			var orientation:String = node.getAttribute("orientation") || DEFAULT_ORIENTATION;
			var isHorizontal:Boolean = orientation == Orientation.HORIZONTAL;

			// Children Width
			for (var i:int = 0; i < node.numChildren; i++)
			{
				var child:Node = node.getChildAt(i);
				var childWidth:Number = child.width.toPixels(ppp, pem, 0, 0);

				childWidth += child.margin.left.toPixels(ppp, pem, 0, 0);
				childWidth += child.margin.right.toPixels(ppp, pem, 0, 0);

				result = isHorizontal ? (result + childWidth) : Math.max(result, childWidth);
			}

			// Gap
			if (isHorizontal)
			{
				gauge.parse(node.getAttribute("gap") || DEFAULT_GAP);
				var gap:Number = gauge.toPixels(ppp, pem, node.bounds.width, 0);
				result += node.numChildren > 1 ? (node.numChildren - 1) * gap : 0;
			}

			// Padding
			result += node.padding.left.toPixels(ppp, pem, 0, 0);
			result += node.padding.right.toPixels(ppp, pem, 0, 0);

			return result;
		}

		public override function measureAutoHeight(node:Node, ppp:Number, pem:Number):Number
		{
			var result:Number = 0;
			var orientation:String = node.getAttribute("orientation") || DEFAULT_ORIENTATION;
			var isVertical:Boolean = orientation == Orientation.VERTICAL;

			// Children Height
			for (var i:int = 0; i < node.numChildren; i++)
			{
				var child:Node = node.getChildAt(i);
				var childHeight:Number = child.height.toPixels(ppp, pem, 0, 0);

				childHeight += child.margin.top.toPixels(ppp, pem, 0, 0);
				childHeight += child.margin.bottom.toPixels(ppp, pem, 0, 0);

				result = isVertical ? (result + childHeight) : Math.max(result, childHeight);
			}

			// Gap
			if (isVertical)
			{
				gauge.parse(node.getAttribute("gap") || DEFAULT_GAP);
				var gap:Number = gauge.toPixels(ppp, pem, node.bounds.height, 0);
				result += node.numChildren > 1 ? (node.numChildren - 1) * gap : 0;
			}

			// Padding
			result += node.padding.top.toPixels(ppp, pem, 0, 0);
			result += node.padding.bottom.toPixels(ppp, pem, 0, 0);

			return result;
		}
	}
}
