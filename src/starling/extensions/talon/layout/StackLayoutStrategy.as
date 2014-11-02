package starling.extensions.talon.layout
{
	import starling.extensions.talon.core.Box;
	import starling.extensions.talon.core.Gauge;

	public class StackLayoutStrategy implements LayoutStrategy
	{
		private static const TOP:String = "top";
		private static const BOTTOM:String = "bottom";
		private static const LEFT:String = "left";
		private static const RIGHT:String = "right";

		private static function isHorizontal(direction:String):Boolean { return direction == LEFT || direction == RIGHT; }
		private static function isVertical(direction:String):Boolean { return direction == TOP || direction == BOTTOM; }

		public function arrange(box:Box, width:int, height:int, ppp:Number, pem:Number):void
		{
			// Layout properties
			var direction:String = box.attributes.stackDirection || BOTTOM;
			var gap:int = Gauge.toPixels(box.attributes.stackGap, ppp, pem, isHorizontal(direction) ? box.layout.bounds.width : box.layout.bounds.height, 0);

			var child:Box;

			//
			// Horizontal
			//
			if (isHorizontal(direction))
			{
				arrangeSide("width", "x", "measureAutoWidth", width, gap, ppp, pem, box);
			}
			else if (isVertical(direction))
			{
				arrangeSide("height", "y", "measureAutoHeight", height, gap, ppp, pem, box);
			}
		}

		private function arrangeSide2():void
		{

		}

		private function arrangeSide(name:String, asix:String, auto:String, value:int, gap:int, ppp:Number, pem:Number, box:Box):void
		{
			var child:Box;

			var starCount:int = 0;
			var starTarget:int = value - (box.children.length > 1 ? (box.children.length - 1) * gap : 0);

			for each (child in box.children)
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

			for each (child in box.children)
			{
				if (child[name].unit == Gauge.STAR)
				{
					child.layout.bounds[name] = child[name].toPixels(ppp, pem, starTarget, starCount);
				}
			}

			var shift:int = 0;
			for each (child in box.children)
			{
				child.layout.bounds[asix] = shift;
				shift += child.layout.bounds[name] + gap;

				// debug
				if (name == "width")
				{
					child.layout.bounds.height = 20;
					child.layout.bounds.y = 0;
				}
				else if (name == "height")
				{
					child.layout.bounds.width = 20;
					child.layout.bounds.x = 0;
				}

				child.layout.commit();
			}
		}

		public function measureAutoWidth(box:Box, ppp:Number, pem:Number):int
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

		public function measureAutoHeight(box:Box, ppp:Number, pem:Number):int
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
