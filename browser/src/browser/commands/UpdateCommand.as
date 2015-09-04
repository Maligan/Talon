package browser.commands
{
	import air.update.ApplicationUpdaterUI;

	import browser.AppConstants;

	import browser.AppController;

	public class UpdateCommand extends Command
	{
		private var _updater:ApplicationUpdaterUI;

		public function UpdateCommand(controller:AppController)
		{
			super(controller);

			_updater = new ApplicationUpdaterUI();
			_updater.updateURL = AppConstants.APP_UPDATE_URL;
		}

		public override function execute():void
		{
			_updater.checkNow();
		}
	}
}