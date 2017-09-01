package talon.browser.desktop.commands
{
	import talon.browser.platform.AppPlatform;
	import talon.browser.platform.utils.Command;

	public class RotateCommand extends Command
	{
		public function RotateCommand(platform:AppPlatform)
		{
			super(platform);
		}

		public  override function execute():void
		{
			platform.profile.setSize(platform.profile.height, platform.profile.width);
		}
	}
}
