package talon.utils
{
	import talon.core.Attribute;
	import talon.core.Node;

	/** @private Measured size. Defined by 'units' and 'amount'. */
	public final class Gauge
	{
		/** Value is not set. This is <code>null</code> analog. */
		public static const NONE:String = "none";
		/** Regular pixel. */
		public static const PX:String = "px";
		/** Density-independent pixel (e.g. retina display set point per pixel as 1:2). */
		public static const DP:String = "dp";
		/** Millimeter. NB! Device independent (absolute) unit. (Correct work only on mobile devices). */
		public static const MM:String = "mm";
		/** Ems has dynamic value, 1em equals 'fontSize' of current node. */
		public static const EM:String = "em";
		/** Relative unit. Percentages target defined by parent node. */
		public static const PERCENT:String = "%";
		/** Relative unit (weight based). Unlike percent stars target defined by parent node and siblings. */
		public static const STAR:String = "*";

		private static const sFormat:RegExp = /^(-?\d*\.?\d+)(px|dp|mm|em|%|\*|)$/;
		private static const sGauge:Gauge = new Gauge(null, null);

		public static function toPixels(string:String, metrics:Metrics, pp100p:Number = 0, auto:Function = null, aa:Number = 0, pps:Number = 0):Number
		{
			sGauge.parse(string);
			sGauge._auto = auto;
			sGauge._metrics = metrics;
			return sGauge.toPixels(pp100p, aa, pps);
		}

		private var _node:Node;
		private var _attributeName:String;
		private var _attribute:Attribute;
		private var _metrics:Metrics;

		private var _unit:String = NONE;
		private var _amount:Number = 0;
		private var _auto:Function = null;

		/** @private */
		public function Gauge(node:Node, attributeName:String)
		{
			_node = node;
			_attributeName = attributeName;
		}

		private function initialize():void
		{
			if (_attribute == null && _node && _attributeName)
			{
				_metrics = _node.metrics;
				_attribute = _node.getOrCreateAttribute(_attributeName);
				_attribute.change.addListener(onChange);
				onChange();
			}
		}

		private function onChange():void
		{
			parse(_attribute.valueCache);
		}

		private function parse(string:String):void
		{
			var exec:Array;
			
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
			else if (exec = sFormat.exec(string))
			{
				_amount = parseFloat(exec[1]);
				_unit = exec[2] || PX;
			}
			else // Fallback to NONE
			{
				_amount = 0;
				_unit = NONE;
			}
		}

		/**
		 * Transform gauge to pixels.
		 *
		 * @param pp100p pixels per 100%
		 * @param aa argument for auto measure
		 * @param pps pixels per star
		 */
		public function toPixels(pp100p:Number = 0, aa:Number = Infinity, pps:Number = 0):Number
		{
			switch (unit)
			{
				case NONE:		return auto ? auto(aa) : 0;
				case PX:		return amount;
				case MM:		return amount * _metrics.ppmm;
				case EM:        return amount * _metrics.ppem;
				case DP:        return amount * _metrics.ppdp;
				case PERCENT:   return amount * pp100p/100;
				case STAR:		return amount * pps;
				default:		throw new Error("Unknown gauge unit: " + unit);
			}
		}

		/** Unit of measurement. */
		public function get unit():String { initialize(); return _unit }

		/** Amount of measurement. */
		public function get amount():Number { initialize(); return _amount }

		/** unit == NONE. */
		public function get isNone():Boolean { return unit == NONE; }

		/** Callback used for transform gauge to pixels (instead using <code>amount</code> property). */
		public function get auto():Function { return _auto }
		public function set auto(value:Function):void { _auto = value; }
	}
}
