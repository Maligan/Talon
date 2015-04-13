package browser.dom.assets
{
	import browser.dom.files.DocumentFileReference;
	import browser.dom.log.DocumentMessage;
	import flash.filesystem.File;

	public class DirectoryAsset extends Asset
	{
		protected override function onRefresh():void
		{
			reportCleanup();

			var children:Vector.<File> = getListing(file.target);
			for each (var child:File in children)
				if (document.files.hasURL(child.url) == false)
					document.files.addReference(new DocumentFileReference(document, child));
		}

		private function getListing(dir:File):Vector.<File>
		{
			var result:Vector.<File> = new <File>[];

			try
			{
				var children:Array = dir.getDirectoryListing();
				for each (var file:File in children)
					if (file.exists) result.push(file);
			}
			catch (e:Error)
			{
				report(DocumentMessage.FILE_FOLDER_LISTING_ERROR, dir.url);
			}
			finally
			{
				return result;
			}
		}
	}
}