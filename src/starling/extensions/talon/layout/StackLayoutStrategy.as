package starling.extensions.talon.layout
{
	import starling.extensions.talon.core.Gauge;
	import starling.extensions.talon.core.Node;

	public class StackLayoutStrategy implements LayoutStrategy
	{
		private static const TOP:String = "top";
		private static const BOTTOM:String = "bottom";
		private static const LEFT:String = "left";
		private static const RIGHT:String = "right";

		private static function isHorizontal(direction:String):Boolean { return direction == LEFT || direction == RIGHT; }
		private static function isVertical(direction:String):Boolean { return direction == TOP || direction == BOTTOM; }

		public function arrange(node:Node, width:Number, height:Number, ppp:Number, pem:Number):void
		{
			// Layout properties
			var direction:String = node.attributes.stackDirection || BOTTOM;
			var gap:Number = Gauge.toPixels(node.attributes.stackGap, ppp, pem, isHorizontal(direction) ? node.layout.bounds.width : node.layout.bounds.height, 0);

			//
			// Horizontal
			//
			if (isHorizontal(direction))
			{
				arrangeSide1("width",  "x",  "measureAutoWidth",  width, gap, ppp, pem, node);
				arrangeSide2("height", "y", "measureAutoHeight", height, gap, ppp, pem, node);
			}
			else if (isVertical(direction))
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
			var deltaX:int = isHorizontal(direction) ? (width - sumWidth) : 0;
			var deltaY:int = isVertical(direction) ? (height - sumHeight) : 0;

			for each (var child:Node in node.children)
			{
				child.layout.bounds.x += deltaX;
				child.layout.bounds.y += deltaY;
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
//			if (direction == BOTTOM || direction == TOP)
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
