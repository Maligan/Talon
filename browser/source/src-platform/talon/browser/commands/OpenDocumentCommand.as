package talon.browser.commands
{
	import talon.browser.document.files.DocumentFileReference;
	import talon.browser.AppConstants;
	import talon.browser.AppPlatform;
	import talon.browser.document.Document;

	import flash.events.Event;
	import flash.filesystem.File;
	import flash.net.FileFilter;

	public class OpenDocumentCommand extends Command
	{
		private var _source:File;

		public function OpenDocumentCommand(platform:AppPlatform, source:File = null)
		{
			super(platform);
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
				var filter:FileFilter = new FileFilter(AppConstants.T_BROWSER_FILE_EXTENSION_NAME, "*." + AppConstants.BROWSER_DOCUMENT_EXTENSION);
				var source:File = new File();
				source.addEventListener(Event.SELECT, onOpenFileSelect);
				source.browseForOpen(AppConstants.T_OPEN_TITLE, [filter]);
			}
		}

		private function onOpenFileSelect(e:Event):void
		{
			openDocument(e.target as File);
		}

		private function openDocument(source:File):void
		{
			platform.document = new Document(source);

			// Add source root
			var sourceRoot:File = getSourceRoot(platform.document);
			var sourceRootReference:DocumentFileReference = new DocumentFileReference(platform.document, sourceRoot);
			platform.document.files.addReference(sourceRootReference);

			// Try open first template
			var templates:Vector.<String> = platform.document.factory.templateIds;
			var template:String = templates.shift();
			if (template) platform.ui.templateId = template;

			// Add document to recent list
			var recent:Array = platform.settings.getValueOrDefault(AppConstants.SETTING_RECENT_DOCUMENTS, Array, []);
			var indexOf:int = recent.indexOf(source.nativePath);
			if (indexOf != -1) recent.splice(indexOf, 1);
			recent.unshift(source.nativePath);
			recent = recent.slice(0, AppConstants.HISTORY_RECENT_MAX);
			platform.settings.setValue(AppConstants.SETTING_RECENT_DOCUMENTS, recent);
		}

		private function getSourceRoot(document:Document):File
		{
			var sourcePathProperty:String = document.properties.getValueOrDefault(AppConstants.PROPERTY_SOURCE_PATH, String);
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