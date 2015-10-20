package talon.browser.commands
{
	import talon.browser.AppPlatform;
	import flash.display.NativeWindow;
	import flash.events.Event;

	import talon.enums.Orientation;

	public class RotateCommand extends Command
	{
		public function RotateCommand(controller:AppPlatform)
		{
			super(controller);
		}

		public override function execute():void
		{
			var max:int = Math.max(controller.profile.height, controller.profile.width);
			var min:int = Math.min(controller.profile.height, controller.profile.width);

			var isPortrait:Boolean = controller.stage.stageHeight > controller.stage.stageWidth;
			if (isPortrait) controller.profile.setSize(max, min);
			else controller.profile.setSize(min, max);
		}
	}
}
