package talon
{
	import starling.events.Event;
	import starling.events.EventDispatcher;

	/** Dispatched after anyone of sub-gauge has been changed. */
	[Event(name="change", type="starling.events.Event")]
	/** Group of 2 gauge. Used for strong typed definition of coordinate/size. */
	public class GaugePair extends EventDispatcher
	{
		/** Defines horizontal component. */
		public const x:Gauge = new Gauge();
		/** Defines vertical component. */
		public const y:Gauge = new Gauge();

		/** @private */
		public function GaugePair()
		{
			x.addEventListener(Event.CHANGE, dispatchEvent);
			y.addEventListener(Event.CHANGE, dispatchEvent);
		}

		/**
		 * Parse string and setup sub gauges.
		 * Parser expects <em>one or two</em> space separated values (else throw ArgumentError):
		 *
		 * <p>If string contains one origin it expanded (e.g. <code>"string"</code> to <code>"string string"</code>).</p>
		 *
		 * <p>
		 * After subgauges parse substrings:
		 * <ul>
		 * <li>x.parse(substring1)</li>
		 * <li>y.parse(substring2)</li>
		 * </ul>
		 * </p>
		 *
		 * @see talon.Gauge#parse()
		 */
		public function parse(string:String):void
		{
			var split:Array = string.split(" ");

			switch (split.length)
			{
				case 1:
					x.parse(split[0]);
					y.parse(split[0]);
					break;
				case 2:
					x.parse(split[0]);
					y.parse(split[1]);
					break;
				default:
					throw new ArgumentError("Input string is not valid: " + string);
			}
		}

		/** @private */
		public function toString():String
		{
			if (x.equals(y))
			{
				return x.toString();
			}

			return [x, y].join(" ");
		}
	}
}
