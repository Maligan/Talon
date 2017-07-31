package talon.browser.desktop.commands
{
	import talon.browser.platform.AppPlatform;
	import talon.browser.platform.utils.Command;

	public class PublishCacheCommand extends Command
	{
		public function PublishCacheCommand(platform:AppPlatform)
		{
			super(platform);
		}

		public override function execute():void
		{
			var cache:Object = platform.document.factory.getCache();
			
			trace(cache);
		}
	}
}
