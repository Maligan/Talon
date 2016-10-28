package talon.browser.platform.utils
{
	import starling.errors.AbstractMethodError;
	import starling.events.EventDispatcher;

	import talon.browser.platform.AppPlatform;

	[Event(name="progress", type="starling.events.Event")]
	[Event(name="change", type="starling.events.Event")]
	public class Command extends EventDispatcher
	{
		private var _platform:AppPlatform;

		public function Command(platform:AppPlatform):void
		{
			_platform = platform;
		}

		/** Command context platform. */
		public final function get platform():AppPlatform
		{
			return _platform;
		}

		/** Execute command. */
		public function execute():void
		{
			throw new AbstractMethodError();
		}

		/** Revert current command. */
		public function rollback():void
		{
			throw new AbstractMethodError();
		}

		/** Cancel command executing (if command is async). */
		public function cancel():void
		{
			throw new AbstractMethodError();
		}

		/** Dispose all inner resources, remove event listeners etc. */
		public function dispose():void
		{
			throw new AbstractMethodError();
		}

		/** Command can be executed. */
		public function get isExecutable():Boolean
		{
			return true;
		}

		/** Command in 'active' state. */
		public function get isActive():Boolean
		{
			return false;
		}
	}
}