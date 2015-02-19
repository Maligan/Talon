package browser.commands
{
	import browser.AppController;
	import browser.popups.Popup;

	public class PopupCommand extends Command
	{
		private var _popup:Popup;
		private var _modal:Boolean;

		public function PopupCommand(controller:AppController, popup:Popup, modal:Boolean)
		{
			super(controller);
			_popup = popup;
			_modal = modal;
		}

		public override function execute():void
		{
			_popup.open(_modal);
		}
	}
}
