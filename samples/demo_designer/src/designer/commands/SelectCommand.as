package designer.commands
{
	import designer.DesignerController;

	public class SelectCommand extends DesignerCommand
	{
		private var _controller:DesignerController;
		private var _prototype:String;

		public function SelectCommand(controller:DesignerController, prototype:String)
		{
			_controller = controller;
			_prototype = prototype;
		}

		public override function execute():void
		{
			_controller.setCurrentPrototype(_prototype);
		}
	}
}
