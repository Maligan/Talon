package talon.browser.commands
{
	import talon.browser.AppController;

	import starling.errors.AbstractMethodError;
	import starling.events.EventDispatcher;

	[Event(name="progress", type="starling.events.Event")]
	[Event(name="change", type="starling.events.Event")]
	public class Command extends EventDispatcher
	{
		private var _controller:AppController;

		public function Command(controller:AppController):void
		{
			_controller = controller;
		}

		public final function get controller():AppController
		{
			return _controller;
		}

		public function execute():void
		{
			throw new AbstractMethodError();
		}

		public function cancel():void
		{
			throw new AbstractMethodError();
		}

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