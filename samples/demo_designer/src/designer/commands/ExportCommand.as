package designer.commands
{
	import deng.fzip.FZip;

	import designer.dom.Document;
	import designer.dom.files.DocumentFileReference;
	import designer.dom.files.DocumentFileType;

	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.utils.ByteArray;

	public class ExportCommand extends DesignerCommand
	{
		private var _document:Document;
		private var _file:File;

		public function ExportCommand(document:Document, file:File)
		{
			_document = document;
			_file = file;
		}

		public override function execute():void
		{
			// Create archive
			var zip:FZip = new FZip();

			for each (var file:DocumentFileReference in _document.files)
			{
				if (file.type == DocumentFileType.DIRECTORY) continue;
				if (file.type == DocumentFileType.UNKNOWN) continue;

				var name:String = _document.getExportFileName(file);
				var data:ByteArray = file.read();
				zip.addFile(name, data);
			}

			writeFile(_file, zip);
		}

		public function writeFile(file:File, zip:FZip):void
		{
			// Save file
			var fileStream:FileStream = new FileStream();

			try
			{
				fileStream.open(file, FileMode.WRITE);
				zip.serialize(fileStream);
			}
			finally
			{
				fileStream.close();
			}
		}
	}
}
