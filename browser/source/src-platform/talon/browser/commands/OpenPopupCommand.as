package talon.browser.commands
{
	import talon.browser.AppPlatform;
	import talon.browser.popups.Popup;

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
			platform.ui.popups.open(popup, _popupData);
		}
	}
}
