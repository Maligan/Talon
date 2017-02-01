package talon.browser.desktop.commands
{
	import flash.display.BitmapData;
	import flash.events.Event;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;

	import starling.core.Starling;
	import starling.display.DisplayObject;
	import starling.display.Stage;
	import starling.rendering.Painter;

	import talon.browser.desktop.plugins.PluginDesktopUI;
	import talon.browser.platform.AppConstants;
	import talon.browser.platform.AppPlatform;
	import talon.browser.platform.utils.Command;

	public class PublishScreenshotCommand extends Command
	{
		private var _ui:PluginDesktopUI;
		private var _output:File;

		public function PublishScreenshotCommand(platform:AppPlatform, ui:PluginDesktopUI, output:File = null)
		{
			super(platform);
			_output = output;
			_ui = ui;
			_ui.addEventListener(Event.CHANGE, onTemplateChange);
		}

		private function onTemplateChange(e:*):void
		{
			dispatchEventWith(Event.CHANGE);
		}

		public override function get isExecutable():Boolean
		{
			return _ui.template;
		}

		public override function execute():void
		{
			if (!isExecutable) return;

			if (_output == null)
			{
				var file:File = new File("/" + platform.templateId + "." + AppConstants.BROWSER_SCREENSHOT_EXTENSION);
				file.addEventListener(Event.SELECT, onOutputFileSelect);
				file.browseForSave(AppConstants.T_SCREENSHOT_TITLE);
			}
			else
			{
				writeToFile(_output);
			}
		}

		private function onOutputFileSelect(e:Event):void
		{
			writeToFile(e.target as File);
		}

		private function writeToFile(file:File):void
		{
			if (file != null)
			{
				var bitmap:BitmapData = _ui.template.drawToBitmapData();
				var bytes:ByteArray = PNGEncoder2.encode(bitmap);

				try
				{
					var stream:FileStream = new FileStream();
					stream.open(file, FileMode.WRITE);
					stream.writeBytes(bytes, 0, bytes.length);
				}
				finally
				{
					stream.close();
					bytes.clear();
				}
			}
		}
	}
}