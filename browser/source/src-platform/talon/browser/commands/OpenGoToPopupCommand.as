package talon.browser.commands
{
	import talon.browser.AppPlatform;
	import talon.browser.AppPlatformEvent;
	import talon.browser.popups.GoToPopup;

	import starling.events.Event;

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
