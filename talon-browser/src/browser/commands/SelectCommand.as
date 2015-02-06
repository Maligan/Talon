package browser.commands
{
	import browser.AppController;

	import starling.events.Event;

	public class SelectCommand extends Command
	{
		private var _controller:AppController;
		private var _prototypeId:String;

		public function SelectCommand(controller:AppController, prototypeId:String)
		{
			_controller = controller;
			_controller.addEventListener(AppController.EVENT_PROTOTYPE_CHANGE, onControllerPrototypeChange);
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
