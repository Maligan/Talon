package browser.commands
{
	import browser.AppController;

	import flash.desktop.NativeApplication;

	public class CloseBrowserCommand extends Command
	{
		public function CloseBrowserCommand(controller:AppController)
		{
			super(controller);
		}

		public override function execute():void
		{
			NativeApplication.nativeApplication.exit();
		}
	}
}
