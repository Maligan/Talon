package designer.commands
{
	import designer.DesignerController;
	import flash.display.NativeWindow;
	import flash.events.Event;

	import starling.extensions.talon.utils.Orientation;

	public class OrientationCommand extends DesignerCommand
	{
		private var _controller:DesignerController;
		private var _orientation:String;

		public function OrientationCommand(controller:DesignerController, orientation:String)
		{
			_controller = controller;
			_controller.monitor.addEventListener(Event.CHANGE, onOrientationChange);
			_orientation = orientation;
		}

		private function onOrientationChange(e:Event):void
		{
			dispatchEventWith(Event.CHANGE);
		}

		public override function execute():void
		{
			if (isActive) return;

			var window:NativeWindow  = _controller.root.stage.nativeWindow;
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
			return (_orientation == Orientation.VERTICAL    && _controller.monitor.isPortrait)
				|| (_orientation == Orientation.HORIZONTAL  && _controller.monitor.isLandscape)
		}
	}
}
