package talon.browser.commands
{
	import talon.browser.AppPlatform;
	import talon.browser.popups.GoToPopup;

	import starling.events.Event;

	public class OpenGoToPopupCommand extends OpenPopupCommand
	{
		public function OpenGoToPopupCommand(controller:AppPlatform)
		{
			super(controller, GoToPopup, controller);

			controller.addEventListener(AppPlatform.EVENT_DOCUMENT_CHANGE, onDocumentChange);
		}

		private function onDocumentChange(e:Event):void
		{
			dispatchEventWith(Event.CHANGE);
		}

		public override function get isExecutable():Boolean
		{
			return controller.document != null;
		}
	}
}
