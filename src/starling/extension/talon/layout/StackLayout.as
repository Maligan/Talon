package starling.extension.talon.layout
{
	import starling.extension.talon.core.Box;
	import starling.extension.talon.core.Gauge;
	import starling.extension.talon.core.Layout;

	import flash.errors.IllegalOperationError;

	public class StackLayout implements Layout
	{
		public static const TOP:String = "top";
		public static const BOTTOM:String = "bottom";
		public static const LEFT:String = "left";
		public static const RIGHT:String = "right";

		private var _target:Box;
		private var _gap:int = 10;
		private var _direction:String;

		public function StackLayout(target:Box)
		{
			_target = target;
			_direction = RIGHT;
		}

		public function arrange(ppp:Number, em:Number, width:int, height:int):void
		{
			var child:Box;

			// Количество "звёзд" в потомках
			var starWidth:int = 0;
			var starHeight:int = 0;

			for each (child in _target.children)
			{
				if (child.width.unit == Gauge.STAR) starWidth += child.width.amount;
				if (child.height.unit == Gauge.STAR) starHeight += child.height.amount;
			}

			// Определение размеров потомков
			for each (child in _target.children)
			{
				child.bounds.width = child.width.isAuto
					? child.layout.measureWidth(ppp, em)
					: child.width.toPixels(ppp, em, width, starWidth);

				child.bounds.height = child.height.isAuto
					? child.layout.measureHeight(ppp, em)
					: child.height.toPixels(ppp, em, height, starHeight);
			}

			// Ранжирование потомков
			var shift:int = 0;
			for each (child in _target.children)
			{
				child.bounds.x = direction == RIGHT ? shift : 0;
				child.bounds.y = direction == BOTTOM ? shift : 0;

				shift += direction == RIGHT ? child.bounds.width : child.bounds.height;
				shift += _gap;

				child.layout.arrange(ppp, em, child.bounds.width, child.bounds.height);
			}
		}

		public function measureWidth(ppp:Number, em:Number):int
		{
			var child:Box;
			var result:int = 0;

			if (direction == BOTTOM || direction == TOP)
			{
				for each (child in _target.children)
				{
					var width:int = child.width.isAuto ? child.layout.measureWidth(ppp, em) : child.width.toPixels(ppp, em, 0, 0);
					result = Math.max(result, width);
				}
			}
			else
			{
				for each (child in _target.children)
				{
					/**/ if (child.width.isRelative) throw new IllegalOperationError("");
					else if (child.width.isAuto) result += child.layout.measureWidth(ppp, em);
					else result += child.width.toPixels(ppp, em, 0, 0);
				}

				result += _target.children.length > 1 ? (_target.children.length - 1) * _gap : 0;
			}

			return result;
		}

		public function measureHeight(ppp:Number, em:Number):int
		{
			var child:Box;
			var result:int = 0;

			if (direction == LEFT || direction == RIGHT)
			{
				for each (child in _target.children)
				{
					var height:int = child.width.isAuto ? child.layout.measureHeight(ppp, em) : child.height.toPixels(ppp, em, 0, 0);
					result = Math.max(result, height);
				}
			}
			else
			{
				for each (child in _target.children)
				{
					/**/ if (child.height.isRelative) throw new IllegalOperationError("");
					else if (child.height.isAuto) result += child.layout.measureHeight(ppp, em);
					else result += child.height.toPixels(ppp, em, 0, 0);
				}

				result += _target.children.length > 1 ? (_target.children.length - 1) * _gap : 0;
			}

			return result;
		}

		/** Направление добавления элеметов. */
		public function get direction():String { return _direction; }
		public function set direction(value:String):void
		{
			_direction = value;
		}
	}
}
