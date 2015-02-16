package browser.commands
{
	import browser.utils.Constants;
	import browser.AppController;

	public class ZoomCommand extends Command
	{
		private var _delta:int;

		public function ZoomCommand(controller:AppController, delta:int)
		{
			super(controller);
			controller.settings.addSettingListener(Constants.SETTING_ZOOM, dispatchEvent);
			_delta = delta;
		}

		public override function execute():void
		{
			var temp:int = zoom + _delta;
			temp = Math.min(temp, Constants.ZOOM_MAX);
			temp = Math.max(temp, Constants.ZOOM_MIN);
			zoom = temp;
		}

		public override function get isExecutable():Boolean
		{
			if (_delta > 0) return zoom < Constants.ZOOM_MAX;
			if (_delta < 0) return zoom > Constants.ZOOM_MIN;
			return true;
		}

		private function get zoom():int { return controller.settings.getValueOrDefault(Constants.SETTING_ZOOM, 100) }
		private function set zoom(value:int):void { controller.settings.setValue(Constants.SETTING_ZOOM, value) }
	}
}
