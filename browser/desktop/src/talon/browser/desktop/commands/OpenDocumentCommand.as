package talon.browser.desktop.commands
{
	import flash.events.Event;
	import flash.filesystem.File;
	import flash.net.FileFilter;

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
			var source:File = null;

			if (root.isDirectory)
				source = root.resolvePath(AppConstants.BROWSER_DEFAULT_DOCUMENT_FILENAME);
			else
				throw new Error(); // TODO: Make error messages like within document

			// NB! Set as current document immediately (before any references)
			var documentProperties:Storage = source.exists ? Storage.fromPropertiesFile(source) : new Storage();
			var document:Document = platform.document = new Document(documentProperties);

			var sourcePathProperty:String = document.properties.getValueOrDefault(DesktopDocumentProperty.SOURCE_PATH, String);
			var sourcePath:File = source.parent.resolvePath(sourcePathProperty || source.parent.nativePath);
			if (sourcePath.exists == false) sourcePath = source.parent;
			var sourcePathReference:DesktopFileReference = new DesktopFileReference(sourcePath, sourcePath);

			// Add source root
			document.files.addReference(sourcePathReference);

			// Set project name
			if (document.properties.getValueOrDefault(DesktopDocumentProperty.DISPLAY_NAME) == null)
				document.properties.setValue(DesktopDocumentProperty.DISPLAY_NAME, sourcePath.name);

			// Set active document

			// Try open first template
			//var templates:Vector.<String> = platform.document.factory.templateIds;
			//var template:String = templates.shift();
			//if (template) platform.templateId = template;

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