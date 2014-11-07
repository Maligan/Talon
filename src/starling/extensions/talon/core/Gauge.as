package starling.extensions.talon.core
{
	import starling.events.Event;
	import starling.events.EventDispatcher;

	/** Measured size. Defined by 'units' and 'amount'. */
	[Event(name="change", type="starling.events.Event")]
	public final class Gauge extends EventDispatcher
	{
		/** Indicates that final value must be defined by measure context. */
		public static const AUTO:String = "auto";
		/** Regular pixel. */
		public static const PX:String = "px";
		/** Typography point equals 1/72 of inch. NB! Device independent unit. */
		public static const PT:String = "pt";
		/** Ems has dynamic value, 1em equals 'fontSize' of current node. */
		public static const EM:String = "em";
		/** Relative unit. Percentages target defined by parent node. */
		public static const PERCENT:String = "%";
		/** Relative unit (weight based). Unlike percent stars target defined by parent node and siblings. */
		public static const STAR:String = "*";

		private static const PATTERN:RegExp = /^(-?\d*\.?\d+)(px|pt|em|%|\*|)$/;

		private var _unit:String = AUTO;
		private var _amount:Number = 0;

		/** Read string and parse it value, throw ArgumentError if string has not valid format. */
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

		/**
		 * Transform gauge to pixels.
		 * @param ppp pixels per point
		 * @param pem pixels per ems
		 * @param target percentages/stars target (in pixels)
		 * @param stars total amount of stars in target
		 */
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

		public function get unit():String { return _unit }
		public function set unit(value:String):void
		{
			if (_unit != unit)
			{
				_unit = unit;
				dispatchEventWith(Event.CHANGE);
			}
		}

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

		/** Unit type is relative depend by parent/siblings. */
		public function get isRelative():Boolean
		{
			return _unit == PERCENT
				|| _unit == STAR;
		}

		/** Unit is AUTO. */
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