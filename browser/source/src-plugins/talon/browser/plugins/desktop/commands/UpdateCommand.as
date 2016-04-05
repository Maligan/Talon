package talon.browser.plugins.desktop.commands
{
	import talon.browser.commands.*;
	import air.update.ApplicationUpdaterUI;

	import talon.browser.AppPlatform;

	public class UpdateCommand extends Command
	{
		private var _updater:ApplicationUpdaterUI;

		public function UpdateCommand(platform:AppPlatform, updater:ApplicationUpdaterUI)
		{
			super(platform);
			 _updater = updater;
		}

		public override function execute():void
		{
			_updater.isCheckForUpdateVisible = true;
			_updater.isDownloadProgressVisible = true;
			_updater.isDownloadUpdateVisible = true;
			_updater.checkNow();
		}
	}
}