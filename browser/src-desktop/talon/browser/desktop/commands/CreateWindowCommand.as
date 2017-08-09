package talon.browser.desktop.commands
{
	import flash.display.NativeWindow;
	import flash.display.NativeWindowInitOptions;
	import flash.display.NativeWindowRenderMode;

	import talon.browser.desktop.DesktopLauncher;
	import talon.browser.platform.utils.Command;

	public class CreateWindowCommand extends Command
	{
		public function CreateWindowCommand()
		{
			super(null);
		}

		public override function execute():void
		{
			var windowOptions:NativeWindowInitOptions = new NativeWindowInitOptions();
			windowOptions.renderMode = NativeWindowRenderMode.DIRECT;

			var window:NativeWindow = new NativeWindow(windowOptions);
			window.activate();

			var launcher:DesktopLauncher = new DesktopLauncher();
			window.stage.addChild(launcher);
		}

		public override function get isExecutable():Boolean
		{
			// Disabled
			return false;
		}
	}
}