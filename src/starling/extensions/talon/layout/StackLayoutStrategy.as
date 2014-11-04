package starling.extensions.talon.layout
{
	import starling.extensions.talon.core.Gauge;
	import starling.extensions.talon.core.Node;
	import starling.extensions.talon.utils.Orientation;

	public class StackLayoutStrategy implements LayoutStrategy
	{
		private static const DEFAULT:String = Orientation.VERTICAL;

		public function arrange(node:Node, ppp:Number, pem:Number, width:Number, height:Number):void
		{
			// Layout properties
			var orientation:String = Orientation.isValid(node.attributes.orientation) ? node.attributes.orientation : DEFAULT;
			var gap:Number = Gauge.toPixels(node.attributes.gap, ppp, pem, (orientation == Orientation.HORIZONTAL) ? node.layout.bounds.width : node.layout.bounds.height, 0);
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
			var sumHeight:Number = node.children.length > 1 ? (node.children.length - 1) * gap : 0;
			var sumWidth:Number = node.children.length > 1 ? (node.children.length - 1) * gap : 0;
			for each (var child:Node in node.children)
			{
				sumHeight += child.layout.bounds.height;
				sumWidth += child.layout.bounds.width;
			}
			var deltaX:Number = (orientation == Orientation.HORIZONTAL) ? (width - sumWidth) : 0;
			var deltaY:Number = (orientation == Orientation.VERTICAL) ? (height - sumHeight) : 0;

			var halign:String = node.attributes.halign;
			var valign:String = node.attributes.valign;
			deltaX = halign == "right" ? deltaX : halign == "center" ? deltaX/2 : 0;
			deltaY = valign == "bottom" ? deltaY : valign == "center" ? deltaY/2 : 0;

			// Padding
			deltaX += node.padding.left.toPixels(ppp, pem, height, 0);
			deltaY += node.padding.top.toPixels(ppp, pem, height, 0);

			for each (var child:Node in node.children)
			{
				var dY:Number = 0;
				var dX:Number = 0;

				if (orientation == Orientation.VERTICAL)
				{
					dX = halign == "right" ? (width - child.layout.bounds.width) : halign == "center" ? (width - child.layout.bounds.width)/2 : 0;
				}

				if (orientation == Orientation.HORIZONTAL)
				{
					dY = valign == "bottom" ? (height - child.layout.bounds.height) : valign == "center" ? (height - child.layout.bounds.height)/2 : 0;
				}

				child.layout.bounds.x += deltaX + dX;
				child.layout.bounds.y += deltaY + dY;
				child.layout.commit();
			}
		}

		private function arrangeSide2(name:String, asix:String, auto:String, value:int, gap:int, ppp:Number, pem:Number, node:Node):void
		{
			for each (var child:Node in node.children)
			{
				child.layout.bounds[name] = child[name].isAuto ? child.layout[auto]() : child[name].toPixels(ppp, pem, value, 0);
				child.layout.bounds[asix] = 0;
			}
		}

		private function arrangeSide1(name:String, asix:String, auto:String, value:int, gap:int, ppp:Number, pem:Number, node:Node):void
		{
			var child:Node;

			var starCount:int = 0;
			var starTarget:int = value - (node.children.length > 1 ? (node.children.length - 1) * gap : 0);

			for each (child in node.children)
			{
				if (child[name].unit == Gauge.STAR)
				{
					starCount += child[name].amount;
				}
				else
				{
					child.layout.bounds[name] = child[name].isAuto ? child.layout[auto]() : child[name].toPixels(ppp, pem, value, 0);
					starTarget -= child.layout.bounds[name];
				}
			}

			for each (child in node.children)
			{
				if (child[name].unit == Gauge.STAR)
				{
					child.layout.bounds[name] = child[name].toPixels(ppp, pem, starTarget, starCount);
				}
			}

			var shift:int = 0;
			for each (child in node.children)
			{
				child.layout.bounds[asix] = shift;
				shift += child.layout.bounds[name] + gap;
			}
		}

		public function measureAutoWidth(node:Node, ppp:Number, pem:Number):Number
		{
			var result:Number = 0;
			var orientation:String = Orientation.isValid(node.attributes.orientation) ? node.attributes.orientation : DEFAULT;
			var isHorizontal:Boolean = orientation == Orientation.HORIZONTAL;

			// Children Width
			for each (var child:Node in node.children)
			{
				var childWidth:Number = child.width.isAuto
					? child.layout.measureAutoWidth()
					: child.width.toPixels(ppp, pem, 0, 0);

				childWidth += child.margin.left.toPixels(ppp, pem, 0, 0);
				childWidth += child.margin.right.toPixels(ppp, pem, 0, 0);

				result = isHorizontal ? (result + childWidth) : Math.max(result, childWidth);
			}

			// Gap
			if (isHorizontal)
			{
				var gap:Number = Gauge.toPixels(node.attributes.gap, ppp, pem, node.layout.bounds.width, 0);
				result += node.children.length > 1 ? (node.children.length - 1) * gap : 0;
			}

			// Padding
			result += node.padding.left.toPixels(ppp, pem, 0, 0);
			result += node.padding.right.toPixels(ppp, pem, 0, 0);

			return result;
		}

		public function measureAutoHeight(node:Node, ppp:Number, pem:Number):Number
		{
			var result:Number = 0;
			var orientation:String = Orientation.isValid(node.attributes.orientation) ? node.attributes.orientation : DEFAULT;
			var isVertical:Boolean = orientation == Orientation.VERTICAL;

			// Children Height
			for each (var child:Node in node.children)
			{
				var childHeight:Number = child.height.isAuto
						? child.layout.measureAutoHeight()
						: child.height.toPixels(ppp, pem, 0, 0);

				childHeight += child.margin.top.toPixels(ppp, pem, 0, 0);
				childHeight += child.margin.bottom.toPixels(ppp, pem, 0, 0);

				result = isVertical ? (result + childHeight) : Math.max(result, childHeight);
			}

			// Gap
			if (isVertical)
			{
				var gap:Number = Gauge.toPixels(node.attributes.gap, ppp, pem, node.layout.bounds.height, 0);
				result += node.children.length > 1 ? (node.children.length - 1) * gap : 0;
			}

			// Padding
			result += node.padding.top.toPixels(ppp, pem, 0, 0);
			result += node.padding.bottom.toPixels(ppp, pem, 0, 0);

			return result;
		}
	}
}
