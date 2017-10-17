package talon.browser.core.utils
{
	import starling.errors.AbstractMethodError;
	import starling.events.Event;
	import starling.events.EventDispatcher;

	import talon.browser.core.App;

	[Event(name="progress", type="starling.events.Event")]
	[Event(name="change", type="starling.events.Event")]
	public class Command extends EventDispatcher
	{
		private var _platform:App;

		public function Command(platform:App):void
		{
			_platform = platform;
		}
		
		public final function dispatchEventChange():void { dispatchEventWith(Event.CHANGE); }

		/** Command context app. */
		public final function get platform():App { return _platform; }
		
		/** Execute command. */
		public function execute():void { throw new AbstractMethodError(); }

		/** Command can be executed. */
		public function get isExecutable():Boolean { return true; }
		
		/** Command is executing right now. */
		public function get isExecuting():Boolean { return false; }

		/** Command in 'active' state (for toggleable commands). */
		public function get isActive():Boolean { return false; }
	}
}