package talon.browser.desktop.commands
{
	import flash.display.StageDisplayState;
	import flash.events.NativeWindowDisplayStateEvent;

	import talon.browser.core.App;
	import talon.browser.core.utils.Command;

	public class ToggleFullScreenCommand extends Command
	{
		public function ToggleFullScreenCommand(platform:App)
		{
			super(platform);

			platform.stage.nativeWindow.addEventListener(NativeWindowDisplayStateEvent.DISPLAY_STATE_CHANGE, onNativeWindowDisplayStateChange);
		}

		private function onNativeWindowDisplayStateChange(e:NativeWindowDisplayStateEvent):void
		{
			dispatchEventChange();
		}

		override public function execute():void
		{
			if (isActive) platform.stage.displayState = StageDisplayState.NORMAL;
			else platform.stage.displayState = StageDisplayState.FULL_SCREEN_INTERACTIVE;
			platform.starling.nextFrame();
		}

		public override function get isActive():Boolean
		{
			return platform.stage.displayState != StageDisplayState.NORMAL;
		}
	}
}
