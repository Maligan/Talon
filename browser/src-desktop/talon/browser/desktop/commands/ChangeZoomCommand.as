package talon.browser.desktop.commands
{
	import talon.browser.platform.AppConstants;
	import talon.browser.platform.AppPlatform;
	import talon.browser.platform.utils.Command;

	public class ChangeZoomCommand extends Command
	{
		private var _delta:int;

		public function ChangeZoomCommand(platform:AppPlatform, delta:int)
		{
			super(platform);
			platform.settings.addPropertyListener(AppConstants.SETTING_ZOOM, dispatchEventChange);
			_delta = delta;
		}

		override public function execute():void
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

		private function get zoom():int { return platform.settings.getValue(AppConstants.SETTING_ZOOM, int, 100) }
		private function set zoom(value:int):void { platform.settings.setValue(AppConstants.SETTING_ZOOM, value) }
	}
}
