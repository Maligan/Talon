package browser.plugins.tools
{
	import browser.AppController;
	import browser.plugins.IPlugin;

	public class DefaultFileTypesPlugin implements IPlugin
	{
		private var _app:AppController;

		public function get id():String
		{
			return "";
		}

		public function get version():String
		{
			return "";
		}

		public function get versionAPI():String
		{
			return "";
		}

		public function attach(app:AppController):void
		{
			_app = app;
		}

		public function detach():void
		{
			_app = null;
		}
	}
}