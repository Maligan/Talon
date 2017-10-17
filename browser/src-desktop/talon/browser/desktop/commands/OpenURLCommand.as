package talon.browser.desktop.commands
{
	import flash.net.URLRequest;
	import flash.net.navigateToURL;

	import talon.browser.core.AppConstants;
	import talon.browser.core.App;
	import talon.browser.core.utils.Command;

	public class OpenURLCommand extends Command
	{
		private var _request:URLRequest;
		
		public function OpenURLCommand(platform:App, url:String)
		{
			super(platform);
			_request = new URLRequest(url);
		}

		override public function execute():void
		{
			navigateToURL(_request);
		}
	}
}
