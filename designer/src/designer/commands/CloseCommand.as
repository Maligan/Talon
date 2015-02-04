package designer.commands
{
	import designer.DesignerController;

	import starling.events.Event;

	public class CloseCommand extends DesignerCommand
	{
		private var _controller:DesignerController;

		public function CloseCommand(controller:DesignerController):void
		{
			_controller = controller;
			_controller.addEventListener(DesignerController.EVENT_DOCUMENT_CHANGE, onDocumentChange);
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