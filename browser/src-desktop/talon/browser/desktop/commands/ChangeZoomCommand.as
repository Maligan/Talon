package talon.browser.desktop.commands
{
	import talon.browser.platform.AppConstants;
	import talon.browser.platform.AppPlatform;
	import talon.browser.platform.utils.Command;

	public class ChangeZoomCommand extends Command
	{
		private var _delta:Number;

		public function ChangeZoomCommand(platform:AppPlatform, delta:Number)
		{
			super(platform);
			platform.settings.addPropertyListener(AppConstants.SETTING_ZOOM, dispatchEventChange);
			_delta = delta;
		}

		override public function execute():void
		{
			var temp:Number = zoom + _delta;
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

		private function get zoom():Number { return platform.settings.getValue(AppConstants.SETTING_ZOOM, Number, 1) }
		private function set zoom(value:Number):void { platform.settings.setValue(AppConstants.SETTING_ZOOM, value) }
	}
}
