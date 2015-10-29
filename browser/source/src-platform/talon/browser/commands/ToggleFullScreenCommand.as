package talon.browser.commands
{
	import talon.browser.AppPlatform;

	import flash.display.StageDisplayState;
	import flash.events.NativeWindowDisplayStateEvent;

	import starling.events.Event;

	public class ToggleFullScreenCommand extends Command
	{
		public function ToggleFullScreenCommand(platform:AppPlatform)
		{
			super(platform);

			platform.stage.nativeWindow.addEventListener(NativeWindowDisplayStateEvent.DISPLAY_STATE_CHANGE, onNativeWindowDisplayStateChange);
		}

		private function onNativeWindowDisplayStateChange(e:NativeWindowDisplayStateEvent):void
		{
			dispatchEventWith(Event.CHANGE);
		}

		public override function execute():void
		{
			if (isActive) platform.stage.displayState = StageDisplayState.NORMAL;
			else platform.stage.displayState = StageDisplayState.FULL_SCREEN_INTERACTIVE;
		}

		public override function get isActive():Boolean
		{
			return platform.stage.displayState != StageDisplayState.NORMAL;
		}
	}
}
