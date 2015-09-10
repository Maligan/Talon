package browser.commands
{
	import browser.AppController;
	import browser.ui.popups.Popup;

	public class OpenPopupCommand extends Command
	{
		private var _popupClass:Class;

		public function OpenPopupCommand(controller:AppController, popupClass:Class)
		{
			super(controller);
			_popupClass = popupClass;
		}

		public override function execute():void
		{
			var popup:Popup = new _popupClass();
			controller.ui.popups.open(popup);
		}
	}
}
