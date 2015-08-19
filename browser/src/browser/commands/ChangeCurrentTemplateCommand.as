package browser.commands
{
	import browser.AppController;

	import starling.events.Event;

	public class ChangeCurrentTemplateCommand extends Command
	{
		private var _prototypeId:String;

		public function ChangeCurrentTemplateCommand(controller:AppController, prototypeId:String)
		{
			super(controller);
			controller.addEventListener(AppController.EVENT_TEMPLATE_CHANGE, onControllerPrototypeChange);
			_prototypeId = prototypeId;
		}

		private function onControllerPrototypeChange(e:Event):void
		{
			dispatchEventWith(Event.CHANGE);
		}

		public override function execute():void
		{
			controller.templateId = _prototypeId;
		}

		public override function get isActive():Boolean
		{
			return controller.templateId == _prototypeId;
		}
	}
}