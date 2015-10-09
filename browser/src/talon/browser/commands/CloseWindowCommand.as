package talon.browser.commands
{
	import talon.browser.AppController;

	import flash.desktop.NativeApplication;

	public class CloseWindowCommand extends Command
	{
		public function CloseWindowCommand(controller:AppController)
		{
			super(controller);
		}

		public override function execute():void
		{
			controller.root.stage.nativeWindow.close();
		}
	}
}
