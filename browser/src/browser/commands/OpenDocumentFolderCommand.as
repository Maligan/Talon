package browser.commands
{
	import browser.AppController;

	import starling.events.Event;

	public class OpenDocumentFolderCommand extends Command
	{
		public function OpenDocumentFolderCommand(controller:AppController)
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
			controller.document.project.parent.openWithDefaultApplication();
		}

		public override function get isExecutable():Boolean
		{
			return controller.document != null;
		}
	}
}