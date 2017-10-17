package talon.browser.desktop.commands
{
	import starling.events.Event;

	import talon.browser.desktop.popups.GoToPopup;
	import talon.browser.core.App;
	import talon.browser.core.AppEvent;

	public class OpenGoToPopupCommand extends OpenPopupCommand
	{
		public function OpenGoToPopupCommand(platform:App)
		{
			super(platform, GoToPopup, platform);

			platform.addEventListener(AppEvent.DOCUMENT_CHANGE, onDocumentChange);
		}

		private function onDocumentChange(e:Event):void
		{
			dispatchEventChange();
		}

		public override function get isExecutable():Boolean
		{
			return platform.document != null;
		}
	}
}
