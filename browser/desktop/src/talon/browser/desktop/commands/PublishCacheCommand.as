package talon.browser.desktop.commands
{
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;

	import starling.events.Event;

	import talon.browser.platform.AppConstants;
	import talon.browser.platform.AppPlatform;
	import talon.browser.platform.AppPlatformEvent;
	import talon.browser.platform.document.files.IFileReference;
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
			var cache:Object = getCache();
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
		
		private function getCache():Object
		{
			var files:Vector.<IFileReference> = platform.document.files.toArray();
			var hidden:Vector.<IFileReference> = new <IFileReference>[];

			for each (var file:IFileReference in files)
				if (PublishCommand.isIgnored(platform, file))
					platform.document.files.removeReference(hidden[hidden.length] = file);
			
			var cache:Object = platform.document.factory.getCache();
			
			while (hidden.length > 0)
				platform.document.files.addReference(hidden.pop());
			
			return cache;
		}

		public override function get isExecutable():Boolean
		{
			return platform.document != null;
		}
	}
}
