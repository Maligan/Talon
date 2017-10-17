package talon.browser.desktop.commands
{
	import flash.display.NativeWindow;
	import flash.display.NativeWindowInitOptions;
	import flash.display.NativeWindowRenderMode;

	import talon.browser.desktop.AppDesktopLauncher;
	import talon.browser.core.utils.Command;

	public class CreateWindowCommand extends Command
	{
		public function CreateWindowCommand()
		{
			super(null);
		}

		override public function execute():void
		{
			var windowOptions:NativeWindowInitOptions = new NativeWindowInitOptions();
			windowOptions.renderMode = NativeWindowRenderMode.DIRECT;

			var window:NativeWindow = new NativeWindow(windowOptions);
			window.activate();

			var launcher:AppDesktopLauncher = new AppDesktopLauncher();
			window.stage.addChild(launcher);
		}

		public override function get isExecutable():Boolean
		{
			// Disabled
			return false;
		}
	}
}