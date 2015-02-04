package designer.commands
{
	import designer.DesignerController;

	import starling.events.Event;
	import starling.extensions.talon.core.Attribute;

	public class ThemeCommand extends DesignerCommand
	{
		private var _controller:DesignerController;
		private var _theme:String;

		public function ThemeCommand(controller:DesignerController, theme:String)
		{
			_controller = controller;
			_controller.ui.isolatorContainer.node.addEventListener(Event.CHANGE, onContainerChange);
			_theme = theme;
		}

		private function onContainerChange(e:Event):void
		{
			if (e.data == Attribute.CLASS)
			{
				dispatchEventWith(Event.CHANGE);
			}
		}

		public override function execute():void
		{
			if (isActive) return;
			_controller.ui.isolatorContainer.node.classes = new <String>[_theme];
		}

		public override function get isActive():Boolean
		{
			return _controller.ui.isolatorContainer.node.classes.indexOf(_theme) != -1;
		}
	}
}
