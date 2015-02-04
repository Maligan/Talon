package designer.dom.assets
{
	import designer.dom.files.DocumentFileReference;
	import designer.utils.findFiles;

	import flash.filesystem.File;

	public class DirectoryAsset extends Asset
	{
		protected override function onRefresh():void
		{
			var files:Vector.<File> = findFiles(file.file, false, false);
			var references:Vector.<DocumentFileReference> = new Vector.<DocumentFileReference>();
			for each (var child:File in files) references[references.length] = new DocumentFileReference(child);
			for each (var reference:DocumentFileReference in references) document.files.addFile(reference);
		}
	}
}