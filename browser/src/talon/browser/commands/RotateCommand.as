package talon.browser.commands
{
	import talon.browser.AppController;
	import flash.display.NativeWindow;
	import flash.events.Event;

	import talon.enums.Orientation;

	public class RotateCommand extends Command
	{
		public function RotateCommand(controller:AppController)
		{
			super(controller);
		}

		public override function execute():void
		{
			if (isActive) return;

			var max:int = Math.max(controller.profile.height, controller.profile.width);
			var min:int = Math.min(controller.profile.height, controller.profile.width);

			controller.orientation.isPortrait
				? controller.profile.setSize(max, min)
				: controller.profile.setSize(min, max);
		}
	}
}
