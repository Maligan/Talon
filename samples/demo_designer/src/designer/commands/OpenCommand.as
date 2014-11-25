package designer.commands
{
	import designer.dom.Document;
	import designer.dom.DocumentFile;

	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.utils.ByteArray;

	public class OpenCommand extends DesignerCommand
	{
		private var _document:Document;
		private var _source:File;

		public function OpenCommand(document:Document, source:File)
		{
			_document = document;
			_source = source;
		}

		public override function execute():void
		{
			var files:Array = read().toString().replace(/^\s*|\s*$/g, "").split("\n");

			for each (var filePath:String in files)
			{
				var projectFile:File = new File(_source.parent.resolvePath(filePath));
				var projectDocumentFile:DocumentFile = new DocumentFile(projectFile);
				_document.addFile(projectDocumentFile, true);
			}

			dispatch && dispatchEventWith(Event.CHANGE);
		}

		public function read():ByteArray
		{
			var result:ByteArray = new ByteArray();
			var stream:FileStream = new FileStream();

			try
			{
				stream.open(_source, FileMode.READ);
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
