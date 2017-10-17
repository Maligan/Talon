package talon.browser.desktop.commands
{
	import flash.display.BitmapData;
	import flash.events.Event;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.utils.ByteArray;

	import talon.browser.desktop.plugins.PluginDesktop;
	import talon.browser.core.AppConstants;
	import talon.browser.core.App;
	import talon.browser.core.utils.Command;

	public class PublishScreenshotCommand extends Command
	{
		private var _desktop:PluginDesktop;
		private var _output:File;

		public function PublishScreenshotCommand(platform:App, ui:PluginDesktop, output:File = null)
		{
			super(platform);
			_output = output;
			_desktop = ui;
			_desktop.addEventListener(Event.CHANGE, onTemplateChange);
		}

		private function onTemplateChange(e:*):void
		{
			dispatchEventChange();
		}

		public override function get isExecutable():Boolean
		{
			return _desktop.template != null;
		}

		override public function execute():void
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
				var bitmap:BitmapData = _desktop.template.drawToBitmapData();
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