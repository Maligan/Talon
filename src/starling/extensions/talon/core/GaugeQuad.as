package starling.extensions.talon.core
{
	import starling.events.Event;
	import starling.events.EventDispatcher;

	public final class GaugeQuad extends EventDispatcher
	{
		public const top:Gauge = new Gauge();
		public const right:Gauge = new Gauge();
		public const bottom:Gauge = new Gauge();
		public const left:Gauge = new Gauge();

		public function GaugeQuad()
		{
			top.addEventListener(Event.CHANGE, dispatchEvent);
			right.addEventListener(Event.CHANGE, dispatchEvent);
			bottom.addEventListener(Event.CHANGE, dispatchEvent);
			left.addEventListener(Event.CHANGE, dispatchEvent);
		}

		public function parse(string:String):void
		{
			var split:Array = string.split(" ");

			if (split.length == 1)
			{
				top.parse(split[0]);
				right.parse(split[0]);
				bottom.parse(split[0]);
				left.parse(split[0]);
			}
			else if (split.length == 2)
			{
				top.parse(split[0]);
				right.parse(split[1]);
				bottom.parse(split[0]);
				left.parse(split[1]);
			}
			else if (split.length == 4)
			{
				top.parse(split[0]);
				right.parse(split[1]);
				bottom.parse(split[2]);
				left.parse(split[3]);
			}
			else
			{
				throw new ArgumentError("Input string is not valid: " + string);
			}
		}

		public function toString():String
		{
			if (top.equals(right) && top.equals(bottom) && top.equals(left))
			{
				return top.toString();
			}
			else if (top.equals(bottom) && right.equals(left))
			{
				return [top, right].join(" ");
			}

			return [top, right, bottom, left].join(" ");
		}
	}
}