package talon.browser.desktop.filetypes
{
	import flash.events.FileListEvent;
	import flash.events.IOErrorEvent;
	import flash.filesystem.File;

	import talon.browser.desktop.utils.DesktopFileReference;
	import talon.browser.platform.document.log.DocumentMessage;

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
				document.files.addReference(new DesktopFileReference(child, file.root));

			document.tasks.end();
		}

		private function onIOError(e:IOErrorEvent):void
		{
			reportMessage(DocumentMessage.FILE_LISTING_ERROR, file.path, e.text);
			document.tasks.end();
		}
	}
}