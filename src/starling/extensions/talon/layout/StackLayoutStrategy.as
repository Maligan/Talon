package starling.extensions.talon.layout
{
	import starling.extensions.talon.core.Gauge;
	import starling.extensions.talon.core.Node;

	public class StackLayoutStrategy implements LayoutStrategy
	{
		private static const HORIZONTAL:String = "horizontal";
		private static const VERTICAL:String = "vertical";

		public function arrange(node:Node, width:Number, height:Number, ppp:Number, pem:Number):void
		{
			// Layout properties
			var orientation:String = node.attributes.orientation || VERTICAL;
			var gap:Number = Gauge.toPixels(node.attributes.gap, ppp, pem, (orientation == HORIZONTAL) ? node.layout.bounds.width : node.layout.bounds.height, 0);
			width -= node.padding.left.toPixels(ppp, pem, width, 0) + node.padding.right.toPixels(ppp, pem, width, 0);
			height -= node.padding.top.toPixels(ppp, pem, height, 0) + node.padding.bottom.toPixels(ppp, pem, height, 0);

			//
			// Horizontal
			//
			if (orientation == HORIZONTAL)
			{
				arrangeSide1("width",  "x",  "measureAutoWidth",  width, gap, ppp, pem, node);
				arrangeSide2("height", "y", "measureAutoHeight", height, gap, ppp, pem, node);
			}
			else if (orientation == VERTICAL)
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
			var deltaX:Number = (orientation == HORIZONTAL) ? (width - sumWidth) : 0;
			var deltaY:Number = (orientation == VERTICAL) ? (height - sumHeight) : 0;

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

				if (orientation == VERTICAL)
				{
					dX = halign == "right" ? (width - child.layout.bounds.width) : halign == "center" ? (width - child.layout.bounds.width)/2 : 0;
				}

				if (orientation == HORIZONTAL)
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
			return 0;
//			var child:Box;
//			var result:int = 0;
//
//			if (direction == VERTICAL || direction == HORIZONTAL)
//			{
//				for each (child in _target.children)
//				{
//					var width:int = child.width.isAuto ? child.layout.measureAutoWidth(ppp, em) : child.width.toPixels(ppp, em, 0, 0);
//					result = Math.max(result, width);
//				}
//			}
//			else
//			{
//				for each (child in _target.children)
//				{
//					/**/ if (child.width.isRelative) throw new IllegalOperationError("");
//					else if (child.width.isAuto) result += child.layout.measureAutoWidth(ppp, em);
//					else result += child.width.toPixels(ppp, em, 0, 0);
//				}
//
//				result += _target.children.length > 1 ? (_target.children.length - 1) * _gap : 0;
//			}
//
//			return result;
		}

		public function measureAutoHeight(node:Node, ppp:Number, pem:Number):Number
		{
			return 0;
//			var child:Box;
//			var result:int = 0;
//
//			if (direction == LEFT || direction == RIGHT)
//			{
//				for each (child in _target.children)
//				{
//					var height:int = child.width.isAuto ? child.layout.measureAutoHeight(ppp, em) : child.height.toPixels(ppp, em, 0, 0);
//					result = Math.max(result, height);
//				}
//			}
//			else
//			{
//				for each (child in _target.children)
//				{
//					/**/ if (child.height.isRelative) throw new IllegalOperationError("");
//					else if (child.height.isAuto) result += child.layout.measureAutoHeight(ppp, em);
//					else result += child.height.toPixels(ppp, em, 0, 0);
//				}
//
//				result += _target.children.length > 1 ? (_target.children.length - 1) * _gap : 0;
//			}
//
//			return result;
		}
	}
}
