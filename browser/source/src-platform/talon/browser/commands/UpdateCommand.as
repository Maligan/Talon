package talon.browser.commands
{
	import talon.browser.AppPlatform;

	public class UpdateCommand extends Command
	{
		public function UpdateCommand(platform:AppPlatform)
		{
			super(platform);
		}

		public override function execute():void
		{
			platform.updater.isCheckForUpdateVisible = true;
			platform.updater.isDownloadProgressVisible = true;
			platform.updater.isDownloadUpdateVisible = true;
			platform.updater.checkNow();
		}
	}
}