package starling.extensions.talon.core
{
	import starling.events.Event;
	import starling.events.EventDispatcher;

	/** Размер. */
	public final class Gauge extends EventDispatcher
	{
		public static const AUTO:String = "auto";
		public static const PX:String = "px";
		public static const PT:String = "pt";
		public static const EM:String = "em";
		public static const PERCENT:String = "%";
		public static const STAR:String = "*";

		private static const PATTERN:RegExp = /^(-?\d*\.?\d+)(px|pt|em|%|\*|)$/;

		public static function toPixels(value:String, ppp:Number, pem:Number, target:Number, stars:int):int
		{
			if (value == null) return 0;
			var gauge:Gauge = new Gauge();
			gauge.parse(value);
			return gauge.toPixels(ppp, pem, target, stars);
		}

		private var _unit:String = AUTO;
		private var _amount:Number = 0;

		public function parse(string:String):void
		{
			const prevUnit:String = _unit;
			const prevAmount:Number = _amount;

			if (string == AUTO)
			{
				_unit = AUTO;
				_amount = 0;
			}
			else if (string == STAR)
			{
				_unit = STAR;
				_amount = 1;
			}
			else
			{
				var match:Array = PATTERN.exec(string);
				if (match == null) throw new ArgumentError("Input string is not valid: " + string);
				_amount = parseFloat(match[1]);
				_unit = match[2] || PX;
			}

			if (prevUnit != _unit || prevAmount != _amount)
			{
				dispatchEventWith(Event.CHANGE);
			}
		}

		/** Strong typed values setup. */
		public function setTo(amount:Number, unit:String):void
		{
			if (_amount != amount || _unit != unit)
			{
				_amount = amount;
				_unit = unit;

				dispatchEventWith(Event.CHANGE);
			}
		}

		/** Перевод значения в приксели, в функцию так же передаются все необходимые коэфициенты/параметры перевода. */
		public function toPixels(ppp:Number, pem:Number, target:Number, stars:int):Number
		{
			switch (unit)
			{
				case AUTO:		return 0;
				case PX:		return amount;
				case PT:		return amount * ppp;
				case EM:        return amount * pem;
				case PERCENT:   return amount * target / 100;
				case STAR:		return amount * target / stars;
				default:		throw new Error();
			}
		}

		/** Единицы измерения. */
		public function get unit():String { return _unit }
		public function set unit(value:String):void
		{
			if (_unit != unit)
			{
				_unit = unit;
				dispatchEventWith(Event.CHANGE);
			}
		}

		/** Количество единиц измерения. */
		public function get amount():Number { return _amount }
		public function set amount(value:Number):void
		{
			if (_amount != value)
			{
				_amount = value;
				dispatchEventWith(Event.CHANGE);
			}
		}

		public function equals(gauge:Gauge):Boolean
		{
			return gauge.unit == unit
				&& gauge.amount == amount;
		}

		/** Значение вычисляется относительно контекста (родителя/братьев). */
		public function get isRelative():Boolean
		{
			return _unit == PERCENT
				|| _unit == STAR;
		}

		/** Значение не задано. */
		public function get isAuto():Boolean
		{
			return _unit == AUTO;
		}

		public function toString():String
		{
			return _unit == AUTO ? AUTO : _unit == STAR && _amount == 1 ? STAR : _amount + _unit;
		}
	}
}