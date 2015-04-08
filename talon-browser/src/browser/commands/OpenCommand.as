package browser.commands
{
	import browser.utils.Constants;
	import browser.AppController;
	import browser.dom.Document;
	import browser.dom.files.DocumentFileReference;
	import browser.utils.parseProperties;

	import flash.events.Event;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.net.FileFilter;
	import flash.utils.ByteArray;

	public class OpenCommand extends Command
	{
		private var _source:File;

		public function OpenCommand(controller:AppController, source:File = null)
		{
			super(controller);
			_source = source;
		}

		public override function execute():void
		{
			if (_source != null)
			{
				openDocument(_source);
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
			openDocument(e.target as File);
		}

		private function openDocument(source:File):void
		{
			controller.document = readDocument(source);

			var recent:Array = controller.settings.getValueOrDefault(Constants.SETTING_RECENT_ARRAY, []);
			var indexOf:int = recent.indexOf(source.nativePath);
			if (indexOf != -1) recent.splice(indexOf, 1);
			recent.unshift(source.nativePath);
			recent = recent.slice(0, Constants.HISTORY_RECENT_MAX);
			controller.settings.setValue(Constants.SETTING_RECENT_ARRAY, recent);
		}

		private function readDocument(documentFile:File):Document
		{
			var properties:Object = parseProperties(readFile(documentFile).toString());
			var document:Document = new Document(properties, documentFile);

			var sourceRoot:File = getSourceRoot(document);
			var sourceRootReference:DocumentFileReference = new DocumentFileReference(document, sourceRoot);
			document.files.addFile(sourceRootReference);

			return document;
		}

		private function getSourceRoot(document:Document):File
		{
			var sourcePathProperty:String = document.properties[Constants.PROPERTY_SOURCE_PATH];
			var sourceFile:File = document.file.parent.resolvePath(sourcePathProperty || document.file.parent.nativePath);
			if (sourceFile.exists == false) sourceFile = document.file.parent;
			return sourceFile;
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