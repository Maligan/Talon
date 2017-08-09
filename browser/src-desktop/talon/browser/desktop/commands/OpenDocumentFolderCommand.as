package talon.browser.desktop.commands
{
	import flash.filesystem.File;

	import starling.events.Event;

	import talon.browser.desktop.utils.DesktopFileReference;
	import talon.browser.platform.AppPlatform;
	import talon.browser.platform.AppPlatformEvent;
	import talon.browser.platform.utils.Command;
	import talon.browser.platform.document.files.IFileReference;

	public class OpenDocumentFolderCommand extends Command
	{
		public function OpenDocumentFolderCommand(platform:AppPlatform)
		{
			super(platform);
			platform.addEventListener(AppPlatformEvent.DOCUMENT_CHANGE, onDocumentChange);
		}

		private function onDocumentChange(e:Event):void
		{
			dispatchEventWith(Event.CHANGE);
		}

		public override function execute():void
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

			// FIXME: If there is symlinks in config - return not real source root
			var fileReferences:Vector.<IFileReference> = platform.document.files.toArray();
			var fileReference:DesktopFileReference = fileReferences.shift() as DesktopFileReference;

			return fileReference ? fileReference.root : null;
		}
	}
}