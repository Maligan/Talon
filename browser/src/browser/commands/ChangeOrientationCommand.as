package browser.commands
{
	import browser.AppController;
	import flash.display.NativeWindow;
	import flash.events.Event;

	import talon.enums.Orientation;

	public class ChangeOrientationCommand extends Command
	{
		private var _orientation:String;

		public function ChangeOrientationCommand(controller:AppController, orientation:String)
		{
			super(controller);
			controller.monitor.addEventListener(Event.CHANGE, onOrientationChange);
			_orientation = orientation;
		}

		private function onOrientationChange(e:Event):void
		{
			dispatchEventWith(Event.CHANGE);
		}

		public override function execute():void
		{
			if (isActive) return;
			controller.rotate();
		}

		public override function get isActive():Boolean
		{
			return (_orientation == Orientation.VERTICAL    && controller.monitor.isPortrait)
				|| (_orientation == Orientation.HORIZONTAL  && controller.monitor.isLandscape)
		}
	}
}
