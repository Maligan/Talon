package starling.extensions.talon.core
{
	import starling.events.Event;
	import starling.events.EventDispatcher;

	/** Group of 2 gauge. Used for strong typed definition of coordinate/size. */
	public class GaugePair extends EventDispatcher
	{
		public const x:Gauge = new Gauge();
		public const y:Gauge = new Gauge();

		public function GaugePair()
		{
			x.addEventListener(Event.CHANGE, dispatchEvent);
			y.addEventListener(Event.CHANGE, dispatchEvent);
		}

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
