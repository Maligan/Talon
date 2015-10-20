package talon.browser.commands
{
	import talon.browser.AppPlatform;

	import flash.desktop.NativeApplication;

	public class CloseWindowCommand extends Command
	{
		public function CloseWindowCommand(controller:AppPlatform)
		{
			super(controller);
		}

		public override function execute():void
		{
			controller.stage.nativeWindow.close();
		}
	}
}
