package browser.commands
{
	import browser.dom.Document;

	import deng.fzip.FZip;

	import browser.AppConstants;

	import browser.AppController;
	import browser.dom.files.DocumentFileReference;

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
				var targetPath:String = getDocumentExportPath(controller.document);
				var target:File = new File(targetPath);
				target.addEventListener(Event.SELECT, onExportFileSelect);
				target.browseForSave(AppConstants.T_EXPORT_TITLE);
			}
		}

		private function onExportFileSelect(e:*):void
		{
			var file:File = File(e.target);
			writeDocument(file);
		}

		private function writeDocument(target:File):void
		{
			// Create archive
			var zip:FZip = new FZip();

			for each (var file:DocumentFileReference in controller.document.files.toArray())
			{
				if (file.isIgnored) continue;
				var name:String = file.exportPath;
				var data:ByteArray = file.readBytes();
				zip.addFile(name, data);
			}

			// Create
			if (zip.getFileCount() == 0) throw new Error("No files for export");

			writeFile(target, zip);
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
			return controller.document != null;
		}

		//
		// Export documents properties
		//
		private function getDocumentExportPath(document:Document):String
		{
			var exportPath:String = document.properties[AppConstants.PROPERTY_EXPORT_PATH];
			if (exportPath == null)
				exportPath = document.project.name.replace(AppConstants.DESIGNER_FILE_EXTENSION, AppConstants.DESIGNER_EXPORT_FILE_EXTENSION);

			var exportPathResolved:String = document.project.parent.resolvePath(exportPath).nativePath;
			return exportPathResolved;
		}
	}
}