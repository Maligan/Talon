package browser.commands
{
	import browser.dom.files.DocumentFileReference;
	import browser.AppConstants;
	import browser.AppController;
	import browser.dom.Document;

	import flash.events.Event;
	import flash.filesystem.File;
	import flash.net.FileFilter;

	public class OpenDocumentCommand extends Command
	{
		private var _source:File;

		public function OpenDocumentCommand(controller:AppController, source:File = null)
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
				var filter:FileFilter = new FileFilter(AppConstants.T_BROWSER_FILE_EXTENSION_NAME, "*." + AppConstants.DESIGNER_FILE_EXTENSION);
				var source:File = new File();
				source .addEventListener(Event.SELECT, onOpenFileSelect);
				source.browseForOpen(AppConstants.T_MENU_FILE_OPEN, [filter]);
			}
		}

		private function onOpenFileSelect(e:Event):void
		{
			openDocument(e.target as File);
		}

		private function openDocument(source:File):void
		{
			controller.document = readDocument(source);

			var recent:Array = controller.settings.getValueOrDefault(AppConstants.SETTING_RECENT_DOCUMENTS, []);
			var indexOf:int = recent.indexOf(source.nativePath);
			if (indexOf != -1) recent.splice(indexOf, 1);
			recent.unshift(source.nativePath);
			recent = recent.slice(0, AppConstants.HISTORY_RECENT_MAX);
			controller.settings.setValue(AppConstants.SETTING_RECENT_DOCUMENTS, recent);
		}

		private function readDocument(documentFile:File):Document
		{
			var document:Document = new Document(documentFile);

			var sourceRoot:File = getSourceRoot(document);
			var sourceRootReference:DocumentFileReference = new DocumentFileReference(document, sourceRoot);
			document.files.addReference(sourceRootReference);

			return document;
		}

		private function getSourceRoot(document:Document):File
		{
			var sourcePathProperty:String = document.properties.getValueOrDefault(AppConstants.PROPERTY_SOURCE_PATH);
			var sourceFile:File = document.project.parent.resolvePath(sourcePathProperty || document.project.parent.nativePath);
			if (sourceFile.exists == false) sourceFile = document.project.parent;
			return sourceFile;
		}

		public override function get isExecutable():Boolean
		{
			return _source == null || _source.exists;
		}
	}
}