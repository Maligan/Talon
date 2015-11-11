package talon.browser.commands
{
	import flash.display.BitmapData;
	import flash.events.Event;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;

	import starling.core.RenderSupport;
	import starling.core.Starling;
	import starling.display.DisplayObject;
	import starling.display.Stage;

	import talon.browser.AppConstants;
	import talon.browser.AppPlatform;

	public class PublishScreenshotCommand extends Command
	{
		private var _output:File;

		public function PublishScreenshotCommand(platform:AppPlatform, output:File = null)
		{
			super(platform);
			platform.addEventListener(AppPlatform.EVENT_DOCUMENT_CHANGE, onDocumentChange);
			_output = output;
		}

		private function onDocumentChange(e:*):void
		{
			dispatchEventWith(Event.CHANGE);
		}

		public override function get isExecutable():Boolean
		{
			return platform.ui && platform.ui.template;
		}

		public override function execute():void
		{
			if (!isExecutable) return;

			if (_output == null)
			{
				_output = new File("/" + platform.ui.templateId + "." + AppConstants.BROWSER_SCREENSHOT_EXTENSION);
				_output.addEventListener(Event.SELECT, onOutputFileSelect);
				_output.browseForSave(AppConstants.T_PROJECT_FILE_TITLE);
			}
			else
			{
				onOutputFileSelect(null);
			}
		}

		private function onOutputFileSelect(e:Event):void
		{
			if (_output != null)
			{
				var bitmap:BitmapData = copyToBitmap(platform.starling, platform.ui.template);
				var bytes:ByteArray = PNGEncoder2.encode(bitmap);

				try
				{
					var stream:FileStream = new FileStream();
					stream.open(_output, FileMode.WRITE);
					stream.writeBytes(bytes, 0, bytes.length);
				}
				finally
				{
					stream.close();
					bytes.clear();
				}

				if (e != null) _output = null;
			}
		}

		public static function copyToBitmap(starling:Starling, displayObject:DisplayObject):BitmapData
		{
			var bounds:Rectangle = new Rectangle();
			displayObject.getBounds(displayObject, bounds);

			var result:BitmapData = new BitmapData(bounds.width, bounds.height, true);
			var stage:Stage = starling.stage;
			var support:RenderSupport = new RenderSupport();

			support.clear(0, 0);
			support.setProjectionMatrix(0, 0, stage.stageWidth, stage.stageHeight);
			support.translateMatrix(-bounds.x, -bounds.y);
			displayObject.render(support, 1.0);
			support.finishQuadBatch();
			support.dispose();

			starling.context.drawToBitmapData(result);
			starling.context.present();

			return result;
		}
	}
}