package talon.browser.plugins.tools.types
{
	import flash.filesystem.File;

	import talon.browser.document.files.DocumentFileReference;
	import talon.browser.document.log.DocumentMessage;

	public class DirectoryAsset extends Asset
	{
		override protected function initialize():void
		{
			document.tasks.begin();

			var children:Vector.<File> = getListing(file.target);

			for each (var child:File in children)
				if (document.files.hasURL(child.url) == false)
					document.files.addReference(new DocumentFileReference(document, child));

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