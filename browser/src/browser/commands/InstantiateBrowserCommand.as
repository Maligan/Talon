package browser.commands
{
	import flash.display.NativeWindow;
	import flash.display.NativeWindowInitOptions;
	import flash.display.NativeWindowRenderMode;

	public class InstantiateBrowserCommand extends Command
	{
		public function InstantiateBrowserCommand()
		{
			super(null);
		}

		public override function execute():void
		{
			var windowOptions:NativeWindowInitOptions = new NativeWindowInitOptions();
			windowOptions.renderMode = NativeWindowRenderMode.DIRECT;

			var window:NativeWindow = new NativeWindow(windowOptions);
			window.activate();

			var launcher:Launcher = new Launcher();
			window.stage.addChild(launcher);
		}
	}
}
