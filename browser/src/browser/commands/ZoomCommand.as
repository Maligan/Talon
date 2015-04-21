package browser.commands
{
	import browser.AppConstants;
	import browser.AppController;

	public class ZoomCommand extends Command
	{
		private var _delta:int;

		public function ZoomCommand(controller:AppController, delta:int)
		{
			super(controller);
			controller.settings.addSettingListener(AppConstants.SETTING_ZOOM, dispatchEvent);
			_delta = delta;
		}

		public override function execute():void
		{
			var temp:int = zoom + _delta;
			temp = Math.min(temp, AppConstants.ZOOM_MAX);
			temp = Math.max(temp, AppConstants.ZOOM_MIN);
			zoom = temp;
		}

		public override function get isExecutable():Boolean
		{
			if (_delta > 0) return zoom < AppConstants.ZOOM_MAX;
			if (_delta < 0) return zoom > AppConstants.ZOOM_MIN;
			return true;
		}

		private function get zoom():int { return controller.settings.getValueOrDefault(AppConstants.SETTING_ZOOM, 100) }
		private function set zoom(value:int):void { controller.settings.setValue(AppConstants.SETTING_ZOOM, value) }
	}
}
