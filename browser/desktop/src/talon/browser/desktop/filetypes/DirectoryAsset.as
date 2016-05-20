package talon.browser.desktop.filetypes
{
	import flash.filesystem.File;

	import talon.browser.desktop.utils.DesktopFileReference;
	import talon.browser.platform.document.log.DocumentMessage;

	public class DirectoryAsset extends Asset
	{
		override protected function activate():void
		{
			document.tasks.begin();

			var children:Vector.<File> = getListing(file.target);

			for each (var child:File in children)
				document.files.addReference(new DesktopFileReference(child, file.root));

			document.tasks.end();
		}

		private function getListing(dir:File):Vector.<File>
		{
			var result:Vector.<File> = new <File>[];

			try
			{
				var children:Array = dir.getDirectoryListing();
				for each (var child:File in children)
					if (child.exists) result.push(child);
			}
			catch (e:Error)
			{
				reportMessage(DocumentMessage.FILE_LISTING_ERROR, dir.url);
			}
			finally
			{
				return result;
			}
		}
	}
}