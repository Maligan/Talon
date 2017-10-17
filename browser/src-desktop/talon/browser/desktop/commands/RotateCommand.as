package talon.browser.desktop.commands
{
	import talon.browser.core.App;
	import talon.browser.core.utils.Command;

	public class RotateCommand extends Command
	{
		public function RotateCommand(platform:App)
		{
			super(platform);
		}

		public  override function execute():void
		{
			platform.profile.setSize(platform.profile.height, platform.profile.width);
		}
	}
}
