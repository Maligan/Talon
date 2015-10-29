package talon.browser.commands
{
	import talon.browser.AppPlatform;
	import flash.display.NativeWindow;
	import flash.events.Event;

	import talon.enums.Orientation;

	public class RotateCommand extends Command
	{
		public function RotateCommand(platform:AppPlatform)
		{
			super(platform);
		}

		public override function execute():void
		{
			var max:int = Math.max(platform.profile.height, platform.profile.width);
			var min:int = Math.min(platform.profile.height, platform.profile.width);

			var isPortrait:Boolean = platform.stage.stageHeight > platform.stage.stageWidth;
			if (isPortrait) platform.profile.setSize(max, min);
			else platform.profile.setSize(min, max);
		}
	}
}
