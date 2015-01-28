package designer.commands
{
	import designer.dom.Document;
	import designer.dom.files.DocumentFileReference;
	import designer.utils.findFiles;
	import designer.utils.parseProperties;

	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.utils.ByteArray;

	public class OpenCommand extends DesignerCommand
	{
		private var _document:Document;
		private var _source:File;

		public function OpenCommand(source:File)
		{
			_source = source;
		}

		public override function execute():void
		{
			var properties:Object = parseProperties(readFile(_source).toString());
			var exportName:String = properties[DesignerConstants.PROPERTY_EXPORT_PATH];
			if (exportName == null) properties[DesignerConstants.PROPERTY_EXPORT_PATH] = _source.name.replace(DesignerConstants.DESIGNER_FILE_EXTENSION, DesignerConstants.ZIP_FILE_EXTENSION);

			_document = new Document(properties);

			// Define sourcePath
			var sourcePathURL:String = properties[DesignerConstants.PROPERTY_SOURCE_PATH];
			if (sourcePathURL == null) sourcePathURL = _source.parent.url;
			var sourcePath:File = _source.parent.resolvePath(sourcePathURL);
			if (sourcePath.exists == false) sourcePath.parent;

			// Setup sourcePath
			_document.setSourcePath(sourcePath);

			// Find all document files
			var files:Vector.<File> = findFiles(sourcePath);

			// Add batch of files to document
			var references:Vector.<DocumentFileReference> = new Vector.<DocumentFileReference>();
			for each (var file:File in files) references[references.length] = new DocumentFileReference(file);
			_document.tasks.begin();
			for each (var reference:DocumentFileReference in references) _document.files.addFile(reference);
			_document.tasks.end();
		}

		private function readFile(file:File):ByteArray
		{
			var result:ByteArray = new ByteArray();
			var stream:FileStream = new FileStream();

			try
			{
				stream.open(file, FileMode.READ);
				stream.readBytes(result, 0, stream.bytesAvailable);
			}
			finally
			{
				stream.close();
			}

			return result;
		}

		public function get document():Document
		{
			return _document;
		}
	}
}
