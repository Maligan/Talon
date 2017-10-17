package talon.browser.desktop.commands
{
	import starling.events.Event;

	import talon.browser.core.App;
	import talon.browser.core.AppEvent;
	import talon.browser.core.utils.Command;

	public class CloseDocumentCommand extends Command
	{
		public function CloseDocumentCommand(platform:App):void
		{
			super(platform);
			platform.addEventListener(AppEvent.DOCUMENT_CHANGE, onDocumentChange);
		}

		private function onDocumentChange(e:Event):void
		{
			dispatchEventChange();
		}

		override public function execute():void
		{
			platform.document && platform.document.dispose();
			platform.document = null;
		}

		public override function get isExecutable():Boolean
		{
			return platform.document != null;
		}
	}
}