package talon.browser.desktop.commands
{
	import flash.filesystem.File;

	import starling.events.Event;

	import talon.browser.desktop.utils.DesktopDocumentProperty;
	import talon.browser.platform.AppPlatform;
	import talon.browser.platform.AppPlatformEvent;
	import talon.browser.platform.utils.Command;

	public class OpenDocumentFolderCommand extends Command
	{
		public function OpenDocumentFolderCommand(platform:AppPlatform)
		{
			super(platform);
			platform.addEventListener(AppPlatformEvent.DOCUMENT_CHANGE, onDocumentChange);
		}

		private function onDocumentChange(e:Event):void
		{
			dispatchEventChange();
		}

		public  override function execute():void
		{
			getSourcePath().openWithDefaultApplication();
		}

		public override function get isExecutable():Boolean
		{
			return getSourcePath() != null;
		}

		private function getSourcePath():File
		{
			if (platform.document == null) return null;

			var documentDir:String = platform.document.properties.getValue(DesktopDocumentProperty.PROJECT_DIR);
			var documentSourcePath:String = platform.document.properties.getValue(DesktopDocumentProperty.SOURCE_PATH);
			
			var documentFile:File = new File(documentDir);
			if (documentSourcePath)
				documentFile = documentFile.resolvePath(documentSourcePath);
			
			return documentFile;
		}
	}
}