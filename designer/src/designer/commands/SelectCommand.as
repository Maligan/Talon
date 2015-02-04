package designer.commands
{
	import designer.DesignerController;

	import starling.events.Event;

	public class SelectCommand extends DesignerCommand
	{
		private var _controller:DesignerController;
		private var _prototypeId:String;

		public function SelectCommand(controller:DesignerController, prototypeId:String)
		{
			_controller = controller;
			_controller.addEventListener(DesignerController.EVENT_PROTOTYPE_CHANGE, onControllerPrototypeChange);
			_prototypeId = prototypeId;
		}

		private function onControllerPrototypeChange(e:Event):void
		{
			dispatchEventWith(Event.CHANGE);
		}

		public override function execute():void
		{
			_controller.prototypeId = _prototypeId;
		}

		public override function get isActive():Boolean
		{
			return _controller.prototypeId == _prototypeId;
		}
	}
}
