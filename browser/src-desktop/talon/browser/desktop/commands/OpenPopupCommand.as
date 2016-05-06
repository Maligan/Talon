package talon.browser.desktop.commands
{
	import talon.browser.platform.AppPlatform;
	import talon.browser.platform.commands.Command;
	import talon.browser.platform.popups.Popup;

	public class OpenPopupCommand extends Command
	{
		private var _popupClass:Class;
		private var _popupData:Object;

		public function OpenPopupCommand(platform:AppPlatform, popupClass:Class, popupData:Object)
		{
			super(platform);
			_popupClass = popupClass;
			_popupData = popupData;
		}

		public override function execute():void
		{
			var popup:Popup = new _popupClass();
			platform.popups.open(popup, _popupData);
		}
	}
}
