package browser.commands
{
	import browser.utils.Constants;
	import browser.AppController;
	import browser.dom.Document;
	import browser.dom.files.DocumentFileReference;
	import browser.utils.findFiles;
	import browser.utils.parseProperties;

	import flash.events.Event;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.net.FileFilter;
	import flash.utils.ByteArray;

	public class OpenCommand extends Command
	{
		private var _controller:AppController;
		private var _source:File;

		public function OpenCommand(controller:AppController, source:File = null)
		{
			_controller = controller;
			_source = source;
		}

		public override function execute():void
		{
			if (_source != null)
			{
				_controller.document = readDocument(_source);
			}
			else
			{
				var filter:FileFilter = new FileFilter(Constants.T_DESIGNER_FILE_EXTENSION_NAME, "*." + Constants.DESIGNER_FILE_EXTENSION);
				var source:File = new File();
				source .addEventListener(Event.SELECT, onOpenFileSelect);
				source.browseForOpen(Constants.T_MENU_FILE_OPEN, [filter]);
			}
		}

		private function onOpenFileSelect(e:Event):void
		{
			_controller.document = readDocument(e.target as File);
		}

		private function readDocument(source:File):Document
		{
			var properties:Object = parseProperties(readFile(source).toString());
			var exportName:String = properties[Constants.PROPERTY_EXPORT_PATH];
			if (exportName == null) properties[Constants.PROPERTY_EXPORT_PATH] = source.name.replace(Constants.DESIGNER_FILE_EXTENSION, Constants.DESIGNER_EXPORT_FILE_EXTENSION);

			var document:Document = new Document(properties);

			// Define sourcePath
			var sourcePathURL:String = properties[Constants.PROPERTY_SOURCE_PATH];
			if (sourcePathURL == null) sourcePathURL = source.parent.url;
			var sourcePath:File = source.parent.resolvePath(sourcePathURL);
			if (sourcePath.exists == false) sourcePath.parent;

			// Setup sourcePath
			document.setSourcePath(sourcePath);

			// Find all document files
			var files:Vector.<File> = findFiles(sourcePath);

			// Add batch of files to document
			var references:Vector.<DocumentFileReference> = new Vector.<DocumentFileReference>();
			for each (var file:File in files) references[references.length] = new DocumentFileReference(document, file);
			document.tasks.begin();
			for each (var reference:DocumentFileReference in references) document.files.addFile(reference);
			document.tasks.end();

			return document;
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
	}
}
