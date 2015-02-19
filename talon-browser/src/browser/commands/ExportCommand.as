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
		private var _target:File;

		public function ExportCommand(controller:AppController, target:File = null)
		{
			super(controller);
			controller.addEventListener(AppController.EVENT_DOCUMENT_CHANGE, onDocumentChange);
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
				writeDocument(_target);
			}
			else
			{
				var target:File = new File(controller.document.exportPath);
				target.addEventListener(Event.SELECT, onExportFileSelect);
				target.browseForSave(Constants.T_EXPORT_TITLE);
			}
		}

		private function onExportFileSelect(e:*):void
		{
			var file:File = File(e.target);
			writeDocument(file);
		}

		private function writeDocument(target:File):void
		{
//			// Create archive
//			var zip:FZip = new FZip();
//
//			for each (var file:DocumentFileReference in controller.document.files.toArray())
//			{
//				if (file.type == DocumentFileType.DIRECTORY) continue;
//				if (file.type == DocumentFileType.UNKNOWN) continue;
//
//				var name:String = controller.document.getExportFileName(file);
//				var data:ByteArray = file.read();
//				zip.addFile(name, data);
//			}
//
//			writeFile(target, zip);
		}

//		private function writeFile(file:File, zip:FZip):void
//		{
//			// Save file
//			var fileStream:FileStream = new FileStream();
//
//			try
//			{
//				fileStream.open(file, FileMode.WRITE);
//				zip.serialize(fileStream);
//			}
//			finally
//			{
//				fileStream.close();
//			}
//		}

		public override function get isExecutable():Boolean
		{
			return controller.document != null;
		}
	}
}