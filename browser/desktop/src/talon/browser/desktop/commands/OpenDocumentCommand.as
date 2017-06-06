package talon.browser.desktop.commands
{
	import flash.events.Event;
	import flash.filesystem.File;
	import flash.net.FileFilter;

	import talon.browser.desktop.popups.GoToPopup;

	import talon.browser.desktop.utils.DesktopDocumentProperty;
	import talon.browser.desktop.utils.DesktopFileReference;
	import talon.browser.platform.AppConstants;
	import talon.browser.platform.AppPlatform;
	import talon.browser.platform.utils.Command;
	import talon.browser.platform.document.Document;
	import talon.browser.platform.utils.Storage;

	public class OpenDocumentCommand extends Command
	{
		private var _source:File;

		public function OpenDocumentCommand(platform:AppPlatform, root:File = null)
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

		private function openDocument(root:File):void
		{
			var config:File = root.resolvePath(AppConstants.BROWSER_DEFAULT_DOCUMENT_FILENAME);

			// NB! Set as current document immediately (before any references)
			var documentProperties:Storage = config.exists ? Storage.fromPropertiesFile(config) : new Storage();
			var document:Document = platform.document = new Document(documentProperties);

			var sourcePathProperty:String = document.properties.getValueOrDefault(DesktopDocumentProperty.SOURCE_PATH, String);
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
				var virtualValue:String = document.properties.getValueOrDefault(virtualName);

				var realFile:File = sourcePath.resolvePath(virtualValue);
				var realFileReference:DesktopFileReference = new DesktopFileReference(realFile, realFile, virtualPath);

				document.files.addReference(realFileReference);
			}

			// Add source root
			document.files.addReference(sourcePathReference);

			// Set project name
			if (document.properties.getValueOrDefault(DesktopDocumentProperty.PROJECT_NAME) == null)
				document.properties.setValue(DesktopDocumentProperty.PROJECT_NAME, sourcePath.name);

			// Add document to recent list
			var recent:Array = platform.settings.getValueOrDefault(AppConstants.SETTING_RECENT_DOCUMENTS, Array, []);
			var indexOf:int = recent.indexOf(root.nativePath);
			if (indexOf != -1) recent.splice(indexOf, 1);
			recent.unshift(root.nativePath);
			recent = recent.slice(0, AppConstants.RECENT_HISTORY);
			platform.settings.setValue(AppConstants.SETTING_RECENT_DOCUMENTS, recent);
		}

		public override function get isExecutable():Boolean
		{
			return _source == null || _source.exists;
		}
	}
}