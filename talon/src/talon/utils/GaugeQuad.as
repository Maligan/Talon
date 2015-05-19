package talon.utils
{
	/** Group of 4 gauge. Used for strong typed definition of rectangle sides. */
	public final class GaugeQuad
	{
		/** On change broadcaster, called when value of gauge pair was changed. */
		public const change:Trigger = new Trigger(this);
		/** Defines top side of the rectangle. */
		public const top:Gauge = new Gauge();
		/** Defines right side of the rectangle. */
		public const right:Gauge = new Gauge();
		/** Defines bottom side of the rectangle. */
		public const bottom:Gauge = new Gauge();
		/** Defines left side of the rectangle. */
		public const left:Gauge = new Gauge();

		/** @private */
		public function GaugeQuad()
		{
			top.change.addListener(change.dispatch);
			right.change.addListener(change.dispatch);
			bottom.change.addListener(change.dispatch);
			left.change.addListener(change.dispatch);
		}

		/**
		 * Parse string and setup sub gauges.
		 * Parser expects up to <em>four</em> space separated values:
		 *
		 * <p>
		 * If source string contains less than four values it expands:
		 * <ul>
		 * <li><code><strong>A</strong></code> to <code><strong>A A A A</strong></code></li>
		 * <li><code><strong>A B</strong></code> to <code><strong>A B A B</strong></code></li>
		 * <li><code><strong>A B C</strong></code> to <code><strong>A B C B</strong></code></li>
		 * </ul>
		 *
		 * After subgauges parse substrings:
		 * <ul>
		 * <li>top.parse(substring1)</li>
		 * <li>right.parse(substring2)</li>
		 * <li>bottom.parse(substring3)</li>
		 * <li>left.parse(substring4)</li>
		 * </ul>
		 * </p>
		 *
		 * @see talon.utils.Gauge#parse()
		 */
		public function parse(string:String):void
		{
			var split:Array = string.split(" ");

			switch (split.length)
			{
				case 1:
					top.parse(split[0]);
					right.parse(split[0]);
					bottom.parse(split[0]);
					left.parse(split[0]);
					break;
				case 2:
					top.parse(split[0]);
					right.parse(split[1]);
					bottom.parse(split[0]);
					left.parse(split[1]);
					break;
				case 3:
					top.parse(split[0]);
					right.parse(split[1]);
					bottom.parse(split[2]);
					left.parse(split[1]);
					break;
				case 4:
					top.parse(split[0]);
					right.parse(split[1]);
					bottom.parse(split[2]);
					left.parse(split[3]);
					break;
				default:
					throw new ArgumentError("Input string is not valid: " + string);
			}
		}

		/** @private */
		public function toString():String
		{
			if (top.equals(right) && top.equals(bottom) && top.equals(left))
			{
				return top.toString();
			}
			else if (!top.equals(bottom) && right.equals(left))
			{
				return [top, left, bottom].join(" ");
			}
			else if (top.equals(bottom) && right.equals(left))
			{
				return [top, right].join(" ");
			}

			return [top, right, bottom, left].join(" ");
		}
	}
}