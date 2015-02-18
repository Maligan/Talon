package browser.dom.assets
{
	import browser.dom.files.DocumentFileReference;
	import browser.utils.findFiles;

	import flash.filesystem.File;

	public class DirectoryAsset extends Asset
	{
		protected override function onRefresh():void
		{
			var files:Vector.<File> = findFiles(file.file, false, false);
			var references:Vector.<DocumentFileReference> = new Vector.<DocumentFileReference>();
			for each (var child:File in files) references[references.length] = new DocumentFileReference(document, child);
			for each (var reference:DocumentFileReference in references) document.files.addFile(reference);
		}
	}
}