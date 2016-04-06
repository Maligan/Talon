package talon.browser.plugins.filetypes.assets
{
	import flash.utils.ByteArray;

	import talon.browser.document.Document;
	import talon.browser.document.files.DocumentFileReference;
	import talon.browser.document.files.IDocumentFileController;
	import talon.browser.document.log.DocumentMessage;

	public class Asset implements IDocumentFileController
	{
		private var _file:DocumentFileReference;
		private var _messages:Vector.<DocumentMessage> = new <DocumentMessage>[];

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
		public final function attach(reference:DocumentFileReference):void
		{
			_file = reference;
			activate();
		}

		public final function detach():void
		{
			reportCleanup();
			deactivate();
			_file = null;
		}

		protected function activate():void
		{
			var isXML:Boolean = file.checkFirstMeaningfulChar("<");
			if (isXML && file.xml == null) reportMessage(DocumentMessage.FILE_CONTAINS_WRONG_XML, file.url);
		}

		protected function deactivate():void
		{
		}

		//
		// Properties
		//
		protected final function get file():DocumentFileReference { return _file; }
		protected final function get document():Document { return _file.document; }
	}
}