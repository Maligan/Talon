package talon.browser.commands
{
	import talon.browser.AppController;

	import starling.events.Event;

	public class CloseDocumentCommand extends Command
	{
		public function CloseDocumentCommand(controller:AppController):void
		{
			super(controller);
			controller.addEventListener(AppController.EVENT_DOCUMENT_CHANGE, onDocumentChange);
		}

		private function onDocumentChange(e:Event):void
		{
			dispatchEventWith(Event.CHANGE);
		}

		public override function execute():void
		{
			controller.document = null;
		}

		public override function get isExecutable():Boolean
		{
			return controller.document != null;
		}
	}
}