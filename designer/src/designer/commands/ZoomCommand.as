package designer.commands
{
	import designer.DesignerController;

	public class ZoomCommand extends DesignerCommand
	{
		private var _controller:DesignerController;
		private var _delta:int;

		public function ZoomCommand(controller:DesignerController, delta:int)
		{
			_controller = controller;
			_controller.settings.addSettingListener(DesignerConstants.SETTING_ZOOM, dispatchEvent);
			_delta = delta;
		}

		public override function execute():void
		{
			var temp:int = zoom + _delta;
			temp = Math.min(temp, DesignerConstants.ZOOM_MAX);
			temp = Math.max(temp, DesignerConstants.ZOOM_MIN);
			zoom = temp;
		}

		public override function get isExecutable():Boolean
		{
			if (_delta > 0) return zoom < DesignerConstants.ZOOM_MAX;
			if (_delta < 0) return zoom > DesignerConstants.ZOOM_MIN;
			return true;
		}

		private function get zoom():int { return _controller.settings.getValueOrDefault(DesignerConstants.SETTING_ZOOM, 100) }
		private function set zoom(value:int):void { _controller.settings.setValue(DesignerConstants.SETTING_ZOOM, value) }
	}
}
