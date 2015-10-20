package talon.browser.commands
{
	import talon.browser.AppPlatform;

	public class UpdateCommand extends Command
	{
		public function UpdateCommand(controller:AppPlatform)
		{
			super(controller);
		}

		public override function execute():void
		{
			controller.updater.isCheckForUpdateVisible = true;
			controller.updater.isDownloadProgressVisible = true;
			controller.updater.isDownloadUpdateVisible = true;
			controller.updater.checkNow();
		}
	}
}