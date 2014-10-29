package starling.extension.talon.core
{
	import flash.events.EventDispatcher;
	import flash.geom.Rectangle;

	import starling.extension.talon.layout.DefaultLayout;
	import starling.extension.talon.layout.StackLayout;

	public class Box extends EventDispatcher
	{
		// Suggested parameters
		public const width:Gauge = new Gauge();
		public const height:Gauge = new Gauge();
		public const layout:Layout = new StackLayout(this);
		public const children:Vector.<Box> = new Vector.<Box>();

		// Result of arranging
		public const bounds:Rectangle = new Rectangle();
	}
}