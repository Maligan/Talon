package browser.commands
{
	import avmplus.getQualifiedClassName;

	import browser.document.Document;
	import browser.document.files.IDocumentFileController;
	import browser.document.files.types.Asset;
	import browser.document.files.types.DirectoryAsset;

	import deng.fzip.FZip;

	import browser.AppConstants;

	import browser.AppController;
	import browser.document.files.DocumentFileReference;

	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.utils.ByteArray;
	import flash.utils.getDefinitionByName;

	import starling.events.Event;

	public class PublishCommand extends Command
	{
		private var _target:File;

		public function PublishCommand(controller:AppController, target:File = null)
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
				if (isIgnored(file)) continue;
				var name:String = file.exportPath;
				var data:ByteArray = file.bytes;
				zip.addFile(name, data);
			}

			// Create
			if (zip.getFileCount() == 0) throw new Error("No files for export");

			writeFile(target, zip);
		}

		/** File is ignored for export. */
		private function isIgnored(file:DocumentFileReference):Boolean
		{
			var fileController:IDocumentFileController = controller.document.files.getController(file.url);
			var fileControllerClassName:String = getQualifiedClassName(fileController);
			var fileControllerClass:Class = getDefinitionByName(fileControllerClassName) as Class;

			if (fileControllerClass == DirectoryAsset) return true;
			if (fileControllerClass == Asset) return true;

			return false;

			//			if (target.isDirectory) return false;
			//
			//			var result:Boolean = false;
			//			var property:String = document.properties.getValueOrDefault(AppConstants.PROPERTY_EXPORT_IGNORE, String);
			//			if (property == null) return false;
			//			var spilt:Array = property.split(/\s*,\s*/);
			//
			//			for each (var pattern:String in spilt)
			//			{
			// 				var glob:Glob = new Glob(pattern);
			//				if (glob.match(exportPath))
			//				{
			//					result = !glob.invert;
			//					if (result == false) break;
			//				}
			//			}
			//
			//			return result;
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
			var exportPath:String = document.properties.getValueOrDefault(AppConstants.PROPERTY_EXPORT_PATH, String);
			if (exportPath == null)
				exportPath = document.project.name.replace(AppConstants.BROWSER_DOCUMENT_EXTENSION, AppConstants.BROWSER_PUBLISH_EXTENSION);

			var exportPathResolved:String = document.project.parent.resolvePath(exportPath).nativePath;
			return exportPathResolved;
		}
	}
}