/**
 * Created by malig on 07.10.2015.
 */
package browser.commands
{
	import browser.AppController;
	import browser.ui.popups.GoToPopup;

	import starling.events.Event;

	public class OpenGoToPopupCommand extends OpenPopupCommand
	{
		public function OpenGoToPopupCommand(controller:AppController)
		{
			super(controller, GoToPopup, controller);

			controller.addEventListener(AppController.EVENT_DOCUMENT_CHANGE, onDocumentChange);
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
