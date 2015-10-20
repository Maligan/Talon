package
{
	import talon.browser.AppPlatform;
	import talon.browser.plugins.IPlugin;

	public class Plugin1 implements IPlugin
	{
		public function get id():String
		{
			return "Plugin1";
		}

		public function get version():String
		{
			return "1.0.0";
		}

		public function get versionAPI():String
		{
			return "0.0.1";
		}

		public function attach(platform:AppPlatform):void
		{
		}

		public function detach():void
		{
		}
	}
}