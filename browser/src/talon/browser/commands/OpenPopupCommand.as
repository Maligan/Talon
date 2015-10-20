package talon.browser.commands
{
	import talon.browser.AppPlatform;
	import talon.browser.popups.Popup;

	public class OpenPopupCommand extends Command
	{
		private var _popupClass:Class;
		private var _popupData:Object;

		public function OpenPopupCommand(controller:AppPlatform, popupClass:Class, popupData:Object)
		{
			super(controller);
			_popupClass = popupClass;
			_popupData = popupData;
		}

		public override function execute():void
		{
			var popup:Popup = new _popupClass();
			controller.ui.popups.open(popup, _popupData);
		}
	}
}
