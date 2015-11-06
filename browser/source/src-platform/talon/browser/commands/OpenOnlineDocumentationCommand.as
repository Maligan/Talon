package talon.browser.commands
{
	import flash.net.URLRequest;
	import flash.net.navigateToURL;

	import talon.browser.AppConstants;
	import talon.browser.AppPlatform;

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
