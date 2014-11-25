package designer.commands
{
	import deng.fzip.FZip;

	import designer.dom.Document;
	import designer.dom.DocumentFile;

	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;

	public class SaveCommand extends DesignerCommand
	{
		private var _document:Document;
		private var _file:File;

		public function SaveCommand(document:Document, file:File)
		{
			_document = document;
			_file = file;
		}

		public override function execute():void
		{
			// Create archive
			var zip:FZip = new FZip();

			for each (var file:DocumentFile in _document.files)
			{
				zip.addFile(_document.getRelativeName(file), file.data);
			}

			// Save file
			var fileStream:FileStream = new FileStream();

			try
			{
				fileStream.open(_file, FileMode.WRITE);
				zip.serialize(fileStream);
			}
			finally
			{
				fileStream.close();
			}
		}
	}
}
