package talon.browser.plugins.desktop.commands
{
	import talon.browser.commands.*;
	import talon.browser.AppPlatform;

	import starling.events.Event;

	import talon.browser.AppPlatformEvent;

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
			platform.document.project.parent.openWithDefaultApplication();
		}

		public override function get isExecutable():Boolean
		{
			return platform.document != null;
		}
	}
}