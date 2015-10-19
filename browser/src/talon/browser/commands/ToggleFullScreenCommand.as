package talon.browser.commands
{
	import talon.browser.AppController;

	import flash.display.StageDisplayState;
	import flash.events.NativeWindowDisplayStateEvent;

	import starling.events.Event;

	public class ToggleFullScreenCommand extends Command
	{
		public function ToggleFullScreenCommand(controller:AppController)
		{
			super(controller);

			controller.stage.nativeWindow.addEventListener(NativeWindowDisplayStateEvent.DISPLAY_STATE_CHANGE, onNativeWindowDisplayStateChange);
		}

		private function onNativeWindowDisplayStateChange(e:NativeWindowDisplayStateEvent):void
		{
			dispatchEventWith(Event.CHANGE);
		}

		public override function execute():void
		{
			if (isActive) controller.stage.displayState = StageDisplayState.NORMAL;
			else controller.stage.displayState = StageDisplayState.FULL_SCREEN_INTERACTIVE;
		}

		public override function get isActive():Boolean
		{
			return controller.stage.displayState != StageDisplayState.NORMAL;
		}
	}
}
