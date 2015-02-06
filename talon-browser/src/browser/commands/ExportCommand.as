package browser.commands
{
	import deng.fzip.FZip;

	import browser.utils.Constants;

	import browser.AppController;
	import browser.dom.files.DocumentFileReference;
	import browser.dom.files.DocumentFileType;

	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.utils.ByteArray;

	import starling.events.Event;

	public class ExportCommand extends Command
	{
		private var _controller:AppController;
		private var _target:File;

		public function ExportCommand(controller:AppController, target:File = null)
		{
			_controller = controller;
			_controller.addEventListener(AppController.EVENT_DOCUMENT_CHANGE, onDocumentChange);
			_target = target;
		}

		private function onDocumentChange(e:Event):void
		{
			dispatchEventWith(Event.CHANGE);
		}

		public override function execute():void
		{
			if (_target != null)
			{
				writeDocument();
			}
			else
			{
				_target = new File("/" + _controller.document.exportFileName);
				_target.addEventListener(Event.SELECT, onExportFileSelect);
				_target.browseForSave(Constants.T_EXPORT_TITLE);
			}
		}

		private function onExportFileSelect(e:*):void
		{
			writeDocument();
		}

		private function writeDocument():void
		{
			// Create archive
			var zip:FZip = new FZip();

			for each (var file:DocumentFileReference in _controller.document.files.toArray())
			{
				if (file.type == DocumentFileType.DIRECTORY) continue;
				if (file.type == DocumentFileType.UNKNOWN) continue;

				var name:String = _controller.document.getExportFileName(file);
				var data:ByteArray = file.read();
				zip.addFile(name, data);
			}

			writeFile(_target, zip);
		}

		private function writeFile(file:File, zip:FZip):void
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

		public override function get isExecutable():Boolean
		{
			return _controller.document != null;
		}
	}
}