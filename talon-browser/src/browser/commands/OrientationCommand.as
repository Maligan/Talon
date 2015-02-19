package browser.commands
{
	import browser.AppController;
	import flash.display.NativeWindow;
	import flash.events.Event;

	import talon.enums.Orientation;

	public class OrientationCommand extends Command
	{
		private var _orientation:String;

		public function OrientationCommand(controller:AppController, orientation:String)
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

			var window:NativeWindow  = controller.root.stage.nativeWindow;
			var min:Number = Math.min(window.width, window.height);
			var max:Number = Math.max(window.width, window.height);

			if (_orientation == Orientation.VERTICAL)
			{
				window.width = min;
				window.height = max;
			}
			else
			{
				window.width = max;
				window.height = min;
			}
		}

		public override function get isActive():Boolean
		{
			return (_orientation == Orientation.VERTICAL    && controller.monitor.isPortrait)
				|| (_orientation == Orientation.HORIZONTAL  && controller.monitor.isLandscape)
		}
	}
}
