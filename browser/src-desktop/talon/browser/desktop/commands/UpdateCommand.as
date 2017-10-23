package talon.browser.desktop.commands
{
	import flash.net.URLRequest;
	import flash.net.navigateToURL;

	import talon.browser.core.AppConstants;
	import talon.browser.core.utils.Command;
	import talon.browser.desktop.plugins.PluginDesktop;

	public class UpdateCommand extends Command
	{
		private var _desktop:PluginDesktop;
		
		public function UpdateCommand(desktop:PluginDesktop)
		{
			super(desktop.platform);
			_desktop = desktop;
		}
		
		public override function execute():void
		{
			var request:URLRequest = new URLRequest(_desktop.updateURL || AppConstants.APP_DOWNLOAD_URL);
			navigateToURL(request);
		}
	}
}
