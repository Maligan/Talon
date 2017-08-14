package talon.browser.platform.utils
{
	import starling.errors.AbstractMethodError;
	import starling.events.EventDispatcher;

	import talon.browser.platform.AppPlatform;
	import talon.browser.platform.AppPlatformEvent;

	[Event(name="progress", type="starling.events.Event")]
	[Event(name="change", type="starling.events.Event")]
	public class Command extends EventDispatcher
	{
		public static const EVENT_CHANGE:String = "COMMAND_CHANGE";
		
		private var _platform:AppPlatform;

		public function Command(platform:AppPlatform):void
		{
			_platform = platform;
		}
		
		public final function dispatchEventChange():void
		{
			dispatchEventWith(EVENT_CHANGE);
			platform.dispatchEventWith(AppPlatformEvent.COMMAND_CHANGE, false, this);
		}

		/** Command context platform. */
		public final function get platform():AppPlatform { return _platform; }
		
		/** Execute command. */
		public function execute():void { throw new AbstractMethodError(); }

		/** Revert current command. */
		public function rollback():void { throw new AbstractMethodError(); }

		/** Cancel command executing (if command is async). */
		public function cancel():void { throw new AbstractMethodError(); }

		/** Dispose all inner resources, remove event listeners etc. */
		public function dispose():void { throw new AbstractMethodError(); }

		/** Command can be executed. */
		public function get isExecutable():Boolean { return true; }
		
		/** Command is executing right now. */
		public function get isExecuting():Boolean { return false; }

		/** Command in 'active' state (for toggleable commands). */
		public function get isActive():Boolean { return false; }
	}
}