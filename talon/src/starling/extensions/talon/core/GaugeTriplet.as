package starling.extensions.talon.core
{
	import flash.events.EventDispatcher;

	public class GaugeTriplet extends EventDispatcher
	{
		public const value:Gauge = new Gauge();
		public const min:Gauge = new Gauge();
		public const max:Gauge = new Gauge();

		public function toPixels():int
		{
			return 0;
		}
	}
}
