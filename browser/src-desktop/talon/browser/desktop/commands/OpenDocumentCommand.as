package talon.browser.desktop.commands
{
	import flash.events.Event;
	import flash.filesystem.File;

	import talon.browser.desktop.utils.DesktopDocumentProperty;
	import talon.browser.desktop.utils.DesktopFileReference;
	import talon.browser.desktop.utils.DesktopStorage;
	import talon.browser.desktop.utils.FileUtil;
	import talon.browser.core.AppConstants;
	import talon.browser.core.App;
	import talon.browser.core.document.Document;
	import talon.browser.core.utils.Command;
	import talon.browser.core.utils.Storage;

	public class OpenDocumentCommand extends Command
	{
		private var _source:File;

		public function OpenDocumentCommand(platform:App, root:File = null)
		{
			super(platform);
			_source = root;
		}

		public override function execute():void
		{
			if (_source != null)
			{
				openDocument(_source);
			}
			else
			{
				var source:File = new File();
				source.addEventListener(Event.SELECT, onOpenFileSelect);
				source.browseForDirectory(AppConstants.T_OPEN_TITLE);
			}
		}

		private function onOpenFileSelect(e:Event):void
		{
			openDocument(e.target as File);
		}

		private function openDocument(dir:File):void
		{
			var config:File = dir.resolvePath(AppConstants.BROWSER_DOCUMENT_FILENAME);

			// NB! Set as current document immediately (before any references)
			var documentProperties:Storage = new DesktopStorage(config);

			// Set project name
			if (documentProperties.getValue(DesktopDocumentProperty.PROJECT_NAME) == null)
				documentProperties.setValue(DesktopDocumentProperty.PROJECT_NAME, dir.name);
			
			var document:Document = new Document(documentProperties);
			document.properties.setValue(DesktopDocumentProperty.PROJECT_DIR, dir.url);
			platform.document = document;
			
			var sourcePathProperty:String = document.properties.getValue(DesktopDocumentProperty.SOURCE_PATH, String);
			var sourcePath:File = config.parent.resolvePath(sourcePathProperty || config.parent.nativePath);
			if (sourcePath.exists == false) sourcePath = config.parent;
			var sourcePathReference:DesktopFileReference = new DesktopFileReference(sourcePath, sourcePath);

			// Add virtual dirs (NB! Before source root, for priority reasons)
			var virtualPattern:RegExp = /\[(.*)]/;
			var virtualNames:Vector.<String> = document.properties.getNames(DesktopDocumentProperty.SOURCE_PATH + "[");

			for each (var virtualName:String in virtualNames)
			{
				var virtualPathSplit:Array = virtualPattern.exec(virtualName);
				if (virtualPathSplit.length < 1) continue;

				var virtualPath:String = String(virtualPathSplit[1]);
				var virtualValue:String = document.properties.getValue(virtualName);

				var realFile:File = sourcePath.resolvePath(virtualValue);
				var realFileReference:DesktopFileReference = new DesktopFileReference(realFile, realFile, virtualPath);

				document.files.addReference(realFileReference);
			}

			// Add source root
			document.files.addReference(sourcePathReference);

			// Add document to recent list
			var recent:Array = platform.settings.getValue(AppConstants.SETTING_RECENT_DOCUMENTS, Array, []);
			var indexOf:int = recent.indexOf(dir.nativePath);
			if (indexOf != -1) recent.splice(indexOf, 1);
			recent.unshift(dir.nativePath);
			recent = recent.slice(0, AppConstants.RECENT_HISTORY);
			platform.settings.setValue(AppConstants.SETTING_RECENT_DOCUMENTS, recent);
		}

		public override function get isExecutable():Boolean
		{
			return _source == null || _source.exists;
		}
	}
}