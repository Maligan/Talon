package browser.dom.files.types
{
	import browser.dom.Document;
	import browser.dom.files.IDocumentFileController;
	import browser.dom.files.DocumentFileReference;
	import browser.dom.log.DocumentMessage;
	import flash.utils.ByteArray;

	public class Asset implements IDocumentFileController
	{
		private var _file:DocumentFileReference;
		private var _messages:Vector.<DocumentMessage> = new <DocumentMessage>[];

		public function setReference(file:DocumentFileReference):void { _file = file; }

		//
		// Utils
		//
		public final function taskBegin():void { document.tasks.begin(); }
		public final function taskEnd():void { document.tasks.end(); }

		public final function reportMessage(message:String, ...args):DocumentMessage
		{
			var msg:DocumentMessage = new DocumentMessage(message, args);
			_messages.push(msg);
			document.messages.addMessage(msg);
			return msg;
		}

		public final function reportCleanup():void
		{
			while (_messages.length)
				document.messages.removeMessage(_messages.pop());
		}

		public final function readFileBytesOrReport():ByteArray
		{
			if (file.bytes == null)
				reportMessage(DocumentMessage.FILE_READ_ERROR, file.url);

			return file.bytes;
		}

		public final function readFileXMLOrReport():XML
		{
			if (file.xml == null)
				reportMessage(DocumentMessage.FILE_CONTAINS_WRONG_XML, file.url);

			return file.xml;
		}

		public final function readFileStringOrReport():String
		{
			var bytes:ByteArray = readFileBytesOrReport();
			return bytes ? bytes.toString() : null;
		}

		//
		// IDocumentFileController
		//
		public function attach():void { }
		public function detach():void { }

		//
		// Properties
		//
		protected final function get file():DocumentFileReference { return _file; }
		protected final function get document():Document { return _file.document; }
	}
}