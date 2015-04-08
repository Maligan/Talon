package browser.dom.assets
{
	import browser.dom.files.DocumentFileReference;
	import flash.filesystem.File;

	public class DirectoryAsset extends Asset
	{
		protected override function onRefresh():void
		{
			var children:Array = file.file.getDirectoryListing();

			for each (var child:File in children)
			{
				var reference:DocumentFileReference = new DocumentFileReference(document, child);
				document.files.addFile(reference);
			}
		}
	}
}