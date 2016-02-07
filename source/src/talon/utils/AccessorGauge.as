package talon.utils
{
	import talon.Attribute;

	/** @private Measured size. Defined by 'units' and 'amount'. */
	public final class AccessorGauge
	{
		/** Value is not set. This is <code>null</code> analog. */
		public static const NONE:String = "none";
		/** Regular pixel. */
		public static const PX:String = "px";
		/** Density-independent pixel (e.g. retina display set point per pixel as 1:2). */
		public static const DP:String = "dp";
		/** Millimeter. NB! Device independent (absolute) unit. (Undesirable to use absolute units. If possible then replace it with em/px). */
		public static const MM:String = "mm";
		/** Ems has dynamic value, 1em equals 'fontSize' of current node. */
		public static const EM:String = "em";
		/** Relative unit. Percentages target defined by parent node. */
		public static const PERCENT:String = "%";
		/** Relative unit (weight based). Unlike percent stars target defined by parent node and siblings. */
		public static const STAR:String = "*";

		private static const PATTERN:RegExp = /^(-?\d*\.?\d+)(px|dp|mm|em|%|\*|)$/;

 		/** @private */
		public static function toPixels(string:String, ppmm:Number, ppem:Number, ppdt:Number, pp100p:Number, aa:Number = 0, ppts:Number = 0, ts:int = 0):Number
		{
			return 0;
		}

		private var _attribute:Attribute;

		private var _unit:String = NONE;
		private var _amount:Number = 0;
		private var _auto:Function = null;

		public function AccessorGauge(attribute:Attribute)
		{
			_attribute = attribute;
			_attribute.change.addListener(onChange);
		}

		private function onChange():void
		{
			var string:String = _attribute.valueCache;

			if (string == NONE)
			{
				_unit = NONE;
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
				if (match == null) throw ArgumentError("Input string is not valid gauge: " + string);
				_amount = parseFloat(match[1]);
				_unit = match[2] || PX;
			}
		}

		/**
		 * @private
		 * Transform gauge to pixels.
		 * Core & Hardcore function.
		 *
		 * @param ppmm pixels per millimeter
		 * @param ppem pixels per em
		 * @param ppdp pixels per density-independent point
		 * @param pp100p pixels per 100%
		 * @param aa argument for auto measure
		 * @param ppts pixels per total stars
		 * @param ts total stars amount
		 */
		public function toPixels(ppmm:Number, ppem:Number, ppdp:Number, pp100p:Number, aa:Number = Infinity, ppts:Number = 0, ts:int = 0):Number
		{
			switch (unit)
			{
				case NONE:		return auto ? auto(aa) : 0;
				case PX:		return amount;
				case MM:		return amount * ppmm;
				case EM:        return amount * ppem;
				case DP:        return amount * ppdp;
				case PERCENT:   return amount * pp100p/100;
				case STAR:		return amount * (ts?(ppts/ts):0);
				default:		throw new Error("Unknown gauge unit: " + unit);
			}
		}

		/** Unit of measurement. */
		public function get unit():String { return _unit }

		/** Amount of measurement. */
		public function get amount():Number { return _amount }

		/** Callback used for transform gauge to pixels (instead using <code>amount</code> property). */
		public function get auto():Function { return _auto }
		public function set auto(value:Function):void
		{
			if (_auto != value)
				_auto = value;
		}

		/** unit == NONE. */
		public function get isNone():Boolean
		{
			return _unit == NONE;
		}

		/** @private */
		public function toString():String
		{
			if (isNone) return NONE;
			if (_unit==STAR && _amount==1) return STAR;

			return _amount + _unit;
		}
	}
}