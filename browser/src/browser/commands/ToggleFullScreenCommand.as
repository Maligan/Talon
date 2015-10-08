/**
 * Created by malig on 06.10.2015.
 */
package browser.commands
{
	import browser.AppController;

	import flash.display.StageDisplayState;
	import flash.events.NativeWindowDisplayStateEvent;

	import starling.events.Event;

	public class ToggleFullScreenCommand extends Command
	{
		public function ToggleFullScreenCommand(controller:AppController)
		{
			super(controller);

			controller.root.stage.nativeWindow.addEventListener(NativeWindowDisplayStateEvent.DISPLAY_STATE_CHANGE, onNativeWindowDisplayStateChange);
		}

		private function onNativeWindowDisplayStateChange(e:NativeWindowDisplayStateEvent):void
		{
			dispatchEventWith(Event.CHANGE);
		}

		public override function execute():void
		{
			if (isActive) controller.root.stage.displayState = StageDisplayState.NORMAL;
			else controller.root.stage.displayState = StageDisplayState.FULL_SCREEN_INTERACTIVE;
		}

		public override function get isActive():Boolean
		{
			return controller.root.stage.displayState != StageDisplayState.NORMAL;
		}
	}
}
