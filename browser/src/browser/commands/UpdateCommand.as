package browser.commands
{
	import browser.AppController;

	public class UpdateCommand extends Command
	{
		public function UpdateCommand(controller:AppController)
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