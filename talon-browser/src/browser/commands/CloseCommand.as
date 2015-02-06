package browser.commands
{
	import browser.AppController;

	import starling.events.Event;

	public class CloseCommand extends Command
	{
		private var _controller:AppController;

		public function CloseCommand(controller:AppController):void
		{
			_controller = controller;
			_controller.addEventListener(AppController.EVENT_DOCUMENT_CHANGE, onDocumentChange);
		}

		private function onDocumentChange(e:Event):void
		{
			dispatchEventWith(Event.CHANGE);
		}

		public override function execute():void
		{
			_controller.document = null;
		}

		public override function get isExecutable():Boolean
		{
			return _controller.document != null;
		}
	}
}