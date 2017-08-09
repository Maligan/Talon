package talon.browser.desktop.commands
{
	import starling.events.Event;

	import talon.browser.desktop.popups.GoToPopup;
	import talon.browser.platform.AppPlatform;
	import talon.browser.platform.AppPlatformEvent;

	public class OpenGoToPopupCommand extends OpenPopupCommand
	{
		public function OpenGoToPopupCommand(platform:AppPlatform)
		{
			super(platform, GoToPopup, platform);

			platform.addEventListener(AppPlatformEvent.DOCUMENT_CHANGE, onDocumentChange);
		}

		private function onDocumentChange(e:Event):void
		{
			dispatchEventWith(Event.CHANGE);
		}

		public override function get isExecutable():Boolean
		{
			return platform.document != null;
		}
	}
}
