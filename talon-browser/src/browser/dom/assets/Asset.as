package browser.dom.assets
{
	import browser.dom.Document;
	import browser.dom.files.DocumentFileController;
	import browser.dom.files.DocumentFileReference;
	import browser.dom.log.DocumentMessage;

	import starling.events.Event;

	internal class Asset implements DocumentFileController
	{
		private var _file:DocumentFileReference;
		private var _messages:Vector.<DocumentMessage> = new <DocumentMessage>[];

		public final function initialize(file:DocumentFileReference):void
		{
			_file = file;
			_file.addEventListener(Event.CHANGE, onFileChange);

			onInclude();
			onRefresh();
		}

		public final function dispose():void
		{
			onExclude();

			_file.removeEventListener(Event.CHANGE, onFileChange);
			_file = null;
		}

		private function onFileChange(e:Event):void
		{
			if (_file.exits) onRefresh();
		}

		/** Called once on asset added to document. */
		protected function onInclude():void { }
		/** Called each time asset file(s) change. */
		protected function onRefresh():void { }
		/** Called once on asset removed from document. */
		protected function onExclude():void { }

		//
		// Utility
		//
		protected function report(message:String, ...params):DocumentMessage
		{
			var msg:DocumentMessage = new DocumentMessage(message, params);
			document.messages.addMessage(msg);
			return msg;
		}

		protected function reportCleanup():void
		{
			while (_messages.length) document.messages.removeMessage(_messages.pop());
		}

		//
		// Properties
		//
		protected function get document():Document
		{
			return _file.document;
		}

		protected function get file():DocumentFileReference
		{
			return _file;
		}
	}
}