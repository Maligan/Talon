package talon.browser.desktop.commands
{
	import deng.fzip.FZip;

	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;

	import starling.events.Event;

	import talon.browser.desktop.filetypes.DirectoryAsset;
	import talon.browser.desktop.utils.DesktopDocumentProperty;
	import talon.browser.desktop.utils.DesktopFileReference;
	import talon.browser.platform.AppConstants;
	import talon.browser.platform.AppPlatform;
	import talon.browser.platform.AppPlatformEvent;
	import talon.browser.platform.utils.Command;
	import talon.browser.platform.document.Document;
	import talon.browser.platform.document.files.IFileController;
	import talon.browser.platform.document.files.IFileReference;
	import talon.browser.platform.utils.Glob;

	public class PublishCommand extends Command
	{
		private var _target:File;

		public function PublishCommand(platform:AppPlatform, target:File = null)
		{
			super(platform);
			platform.addEventListener(AppPlatformEvent.DOCUMENT_CHANGE, onDocumentChange);
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

			for each (var file:IFileReference in platform.document.files.toArray())
			{
				if (isIgnored(file)) continue;
				zip.addFile(file.path, file.data);
			}

			// Create
//			if (zip.getFileCount() == 0) throw new Error("No files for export");

			writeFile(target, zip);
		}

		/** File is ignored for export. */
		private function isIgnored(file:IFileReference):Boolean
		{
			var fileController:IFileController = platform.document.files.getController(file.path);
			if (fileController is DirectoryAsset) return true;

			var patternsString:String = platform.document.properties.getValueOrDefault(DesktopDocumentProperty.SOURCE_PATTERN, String);
			if (patternsString == null) return false;

			return !Glob.matchPattern(file.path, patternsString);
		}


		private function writeFile(file:File, zip:FZip):void
		{
			// Save file
			var fileStream:FileStream = new FileStream();

			try
			{
				fileStream.open(file, FileMode.WRITE);

				if (zip.getFileCount() != 0)
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
			var sourcePath:File = getSourcePath(document);
			if (sourcePath)
			{
				var exportPath:String = document.properties.getValueOrDefault(DesktopDocumentProperty.EXPORT_PATH, String);
				if (exportPath)
					return sourcePath.resolvePath(exportPath).nativePath;
				else
					return sourcePath.parent.resolvePath(sourcePath.name + "." + AppConstants.BROWSER_PUBLISH_EXTENSION).nativePath;
			}

			return document.properties.getValueOrDefault(DesktopDocumentProperty.PROJECT_NAME, String)
				+ "."
				+ AppConstants.BROWSER_PUBLISH_EXTENSION;
		}

		private function getSourcePath(document:Document):File
		{
			if (document == null) return null;

			var fileReferences:Vector.<IFileReference> = document.files.toArray();
			var fileReference:DesktopFileReference = fileReferences.shift() as DesktopFileReference;

			return fileReference ? fileReference.root : null;
		}
	}
}