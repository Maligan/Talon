package starling.extension.talon.core
{
	public final class GaugeQuad
	{
		public const top:Gauge = new Gauge();
		public const right:Gauge = new Gauge();
		public const bottom:Gauge = new Gauge();
		public const left:Gauge = new Gauge();

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
				throw new ArgumentError("Input string is not valid size quad: " + string);
			}
		}

		public function toString():String
		{
			return [top, right, bottom, left].join(" ");
		}
	}
}