package talon.browser.desktop.commands
{
	import air.update.ApplicationUpdaterUI;

	import flash.events.Event;

	import talon.browser.desktop.popups.UpdatePopup;

	import talon.browser.desktop.utils.Updater;
	import talon.browser.platform.AppConstants;
	import talon.browser.platform.AppPlatform;
	import talon.browser.platform.utils.Command;
	import talon.browser.platform.utils.Console;

	public class UpdateCommand extends Command
	{
		private var _updater:Updater;
		private var _popup:UpdatePopup;

		public function UpdateCommand(platform:AppPlatform, popup:UpdatePopup)
		{
			super(platform);

			_popup = popup;
			_updater = new Updater(AppConstants.APP_UPDATE_URL, AppConstants.APP_VERSION);
		}

		public override function execute():void
		{
//			var updater:Updater = new Updater(AppConstants.APP_UPDATE_URL, "0.0.0");

//			updater.addEventListener(Event.COMPLETE, function(e:Event):void
//			{
//				Console(platform.stage.getChildAt(2)).println(updater.lastStatus, updater.lastUpdaterVersion, updater.lastUpdaterDescription);
//			});

//			updater.execute(true);

//			var updater:Updater = new Updater(AppConstants.APP_UPDATE_URL, AppConstants.APP_VERSION);
//			_updater.isCheckForUpdateVisible = true;
//			_updater.isDownloadProgressVisible = true;
//			_updater.isDownloadUpdateVisible = true;
//			_updater.checkNow();
		}
	}
}