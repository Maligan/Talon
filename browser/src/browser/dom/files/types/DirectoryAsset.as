package browser.dom.files.types
{
	import browser.dom.files.DocumentFileReference;
	import browser.dom.log.DocumentMessage;

	import flash.filesystem.File;

	public class DirectoryAsset extends Asset
	{
		public override function attach():void
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

		public override function detach():void
		{
			reportCleanup();
		}
	}
}