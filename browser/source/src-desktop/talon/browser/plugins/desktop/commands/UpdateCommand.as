package talon.browser.plugins.desktop.commands
{
	import air.update.ApplicationUpdaterUI;

	import flash.events.Event;

	import talon.browser.AppConstants;
	import talon.browser.AppPlatform;
	import talon.browser.commands.*;
	import talon.browser.utils.Console;
	import talon.browser.utils.Updater;

	public class UpdateCommand extends Command
	{
		private var _updater:ApplicationUpdaterUI;

		public function UpdateCommand(platform:AppPlatform, updater:ApplicationUpdaterUI)
		{
			super(platform);

//			 _updater = updater;
		}

		public override function execute():void
		{
			var updater:Updater = new Updater(AppConstants.APP_UPDATE_URL, "0.0.0");
			updater.addEventListener(Event.COMPLETE, function(e:Event):void
			{
				Console(platform.stage.getChildAt(2)).println(updater.lastStatus, updater.lastUpdaterVersion, updater.lastUpdaterDescription);
			});

			updater.execute(true);

//			var updater:Updater = new Updater(AppConstants.APP_UPDATE_URL, AppConstants.APP_VERSION);
//			_updater.isCheckForUpdateVisible = true;
//			_updater.isDownloadProgressVisible = true;
//			_updater.isDownloadUpdateVisible = true;
//			_updater.checkNow();
		}
	}
}