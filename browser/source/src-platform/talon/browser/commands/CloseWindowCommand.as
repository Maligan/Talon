package talon.browser.commands
{
	import talon.browser.AppPlatform;

	import flash.desktop.NativeApplication;

	public class CloseWindowCommand extends Command
	{
		public function CloseWindowCommand(platform:AppPlatform)
		{
			super(platform);
		}

		public override function execute():void
		{
			platform.stage.nativeWindow.close();
		}
	}
}
