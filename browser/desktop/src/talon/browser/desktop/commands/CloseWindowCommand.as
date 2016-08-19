package talon.browser.desktop.commands
{
	import talon.browser.platform.AppPlatform;
	import talon.browser.platform.commands.Command;

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
