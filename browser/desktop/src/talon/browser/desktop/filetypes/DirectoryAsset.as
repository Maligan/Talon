package talon.browser.desktop.filetypes
{
	import flash.events.FileListEvent;
	import flash.events.IOErrorEvent;
	import flash.filesystem.File;

	import talon.browser.desktop.utils.DesktopDocumentProperty;

	import talon.browser.desktop.utils.DesktopFileReference;
	import talon.browser.platform.document.files.IFileReference;
	import talon.browser.platform.document.log.DocumentMessage;
	import talon.browser.platform.utils.Glob;

	public class DirectoryAsset extends Asset
	{
		protected override function activate():void
		{
			document.tasks.begin();
			file.target.addEventListener(FileListEvent.DIRECTORY_LISTING, onDirectoryListing);
			file.target.addEventListener(IOErrorEvent.IO_ERROR, onIOError);
			file.target.getDirectoryListingAsync();
		}

		protected override function deactivate():void
		{
			file.target.removeEventListener(FileListEvent.DIRECTORY_LISTING, onDirectoryListing);
			file.target.removeEventListener(IOErrorEvent.IO_ERROR, onIOError);
		}

		private function onDirectoryListing(e:FileListEvent):void
		{
			for each (var child:File in e.files)
			{
				var ref:IFileReference = new DesktopFileReference(child, file.root, file.rootPrefix);
				var refIncluded:Boolean = isIncluded(ref);
				if (refIncluded)
					document.files.addReference(ref);
			}

			document.tasks.end();
		}

		private function isIncluded(file:IFileReference):Boolean
		{
			var patterns:String = document.properties.getValueOrDefault(DesktopDocumentProperty.SOURCE_PATTERN, String);
			if (patterns == null) return true;
			return Glob.matchPattern(file.path, patterns);
		}

		private function onIOError(e:IOErrorEvent):void
		{
			reportMessage(DocumentMessage.FILE_LISTING_ERROR, file.path, e.text);
			document.tasks.end();
		}
	}
}