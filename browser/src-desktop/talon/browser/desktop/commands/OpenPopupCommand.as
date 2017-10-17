package talon.browser.desktop.commands
{
	import talon.browser.core.App;
	import talon.browser.core.utils.Command;
	import talon.browser.core.popups.Popup;

	public class OpenPopupCommand extends Command
	{
		private var _popupClass:Class;
		private var _popupData:Object;

		public function OpenPopupCommand(platform:App, popupClass:Class, popupData:Object)
		{
			super(platform);
			_popupClass = popupClass;
			_popupData = popupData;
		}

		override public function execute():void
		{
			var popup:Popup = new _popupClass();
			platform.popups.open(popup, _popupData);
		}
	}
}
