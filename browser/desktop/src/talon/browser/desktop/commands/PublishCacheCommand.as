package talon.browser.desktop.commands
{
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;

	import starling.events.Event;

	import talon.browser.platform.AppConstants;
	import talon.browser.platform.AppPlatform;
	import talon.browser.platform.AppPlatformEvent;
	import talon.browser.platform.utils.Command;

	public class PublishCacheCommand extends Command
	{
		public function PublishCacheCommand(platform:AppPlatform)
		{
			super(platform);
			platform.addEventListener(AppPlatformEvent.DOCUMENT_CHANGE, onDocumentChange);
		}

		private function onDocumentChange(e:Event):void
		{
			dispatchEventWith(Event.CHANGE);
		}

		public override function execute():void
		{
			var target:File = new File();
			target.addEventListener(Event.SELECT, onExportFileSelect);
			target.browseForSave(AppConstants.T_EXPORT_TITLE);
		}

		private function onExportFileSelect(e:*):void
		{
			var cache:Object = platform.document.factory.getCache();
			var cacheJSON:String = JSON.stringify(cache);

			var file:File = File(e.target);
			var fileStream:FileStream = new FileStream();

			try
			{
				fileStream.open(file, FileMode.WRITE);
				fileStream.writeUTFBytes(cacheJSON);
			}
			finally
			{
				fileStream.close();
			}
		}

		public override function get isExecutable():Boolean
		{
			return platform.document != null;
		}
	}
}
