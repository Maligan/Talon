package talon.browser.desktop.commands
{
	import talon.browser.core.App;
	import talon.browser.core.utils.Command;

	public class CloseWindowCommand extends Command
	{
		public function CloseWindowCommand(platform:App)
		{
			super(platform);
		}

		public override function execute():void
		{
			platform.stage.nativeWindow.close();
		}
	}
}
