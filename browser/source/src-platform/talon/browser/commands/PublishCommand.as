package talon.browser.commands
{
	import avmplus.getQualifiedClassName;

	import talon.browser.document.Document;
	import talon.browser.document.files.IDocumentFileController;
	import talon.browser.plugins.tools.types.Asset;
	import talon.browser.plugins.tools.types.DirectoryAsset;
	import talon.browser.utils.Glob;

	import deng.fzip.FZip;

	import talon.browser.AppConstants;

	import talon.browser.AppPlatform;
	import talon.browser.document.files.DocumentFileReference;

	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.utils.ByteArray;
	import flash.utils.getDefinitionByName;

	import starling.events.Event;

	public class PublishCommand extends Command
	{
		private var _target:File;

		public function PublishCommand(platform:AppPlatform, target:File = null)
		{
			super(platform);
			platform.addEventListener(AppPlatform.EVENT_DOCUMENT_CHANGE, onDocumentChange);
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
				var targetPath:String = getDocumentExportPath(platform.document);
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

			for each (var file:DocumentFileReference in platform.document.files.toArray())
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
			var fileController:IDocumentFileController = platform.document.files.getController(file.url);
			var fileControllerClassName:String = getQualifiedClassName(fileController);
			var fileControllerClass:Class = getDefinitionByName(fileControllerClassName) as Class;

			if (fileControllerClass == DirectoryAsset) return true;
			if (fileControllerClass == Asset) return true;

			var patternsString:String = platform.document.properties.getValueOrDefault(AppConstants.PROPERTY_EXPORT_IGNORE, String);
			if (patternsString == null) return false;

			var patterns:Array = patternsString.replace(/[\n\r\s]/, "").split(",");
			return Glob.match(file.exportPath, patterns);
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
			return platform.document != null;
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