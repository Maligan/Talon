package talon.browser.commands
{
	import talon.browser.AppPlatform;

	import starling.errors.AbstractMethodError;
	import starling.events.EventDispatcher;

	[Event(name="progress", type="starling.events.Event")]
	[Event(name="change", type="starling.events.Event")]
	public class Command extends EventDispatcher
	{
		private var _controller:AppPlatform;

		public function Command(controller:AppPlatform):void
		{
			_controller = controller;
		}

		public final function get controller():AppPlatform
		{
			return _controller;
		}

		/** Execute command. */
		public function execute():void
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

		public function get isExecutable():Boolean
		{
			return true;
		}

		public function get isActive():Boolean
		{
			return false;
		}
	}
}