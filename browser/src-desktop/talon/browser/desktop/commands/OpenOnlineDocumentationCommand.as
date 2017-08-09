package talon.browser.desktop.commands
{
	import flash.net.URLRequest;
	import flash.net.navigateToURL;

	import talon.browser.platform.AppConstants;
	import talon.browser.platform.AppPlatform;
	import talon.browser.platform.utils.Command;

	public class OpenOnlineDocumentationCommand extends Command
	{
		public function OpenOnlineDocumentationCommand(platform:AppPlatform)
		{
			super(platform);
		}

		public override function execute():void
		{
			var request:URLRequest = new URLRequest(AppConstants.APP_DOCUMENTATION_URL);
			navigateToURL(request);
		}
	}
}
