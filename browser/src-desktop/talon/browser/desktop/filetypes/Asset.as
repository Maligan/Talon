package talon.browser.desktop.filetypes
{
	import flash.utils.ByteArray;

	import talon.browser.desktop.utils.DesktopFileReference;
	import talon.browser.platform.document.Document;
	import talon.browser.platform.document.files.IFileController;
	import talon.browser.platform.document.files.IFileReference;
	import talon.browser.platform.document.log.DocumentMessage;

	internal class Asset implements IFileController
	{
		private var _document:Document;
		private var _file:DesktopFileReference;
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

		public final function readFileBytesOrReportAndNull():ByteArray
		{
			if (file.cacheError != null)
			{
				reportMessage(DocumentMessage.FILE_READ_ERROR, file.path, file.cacheError.message);
				return null;
			}

			return file.cacheBytes;
		}

		public final function readFileXMLOrReportAndNull():XML
		{
			if (file.cacheXML == null)
			{
				reportMessage(DocumentMessage.FILE_CONTAINS_WRONG_XML, file.path);
				return null;
			}

			return file.cacheXML;
		}

		public final function readFileStringOrReport():String
		{
			var bytes:ByteArray = readFileBytesOrReportAndNull();
			return bytes ? bytes.toString() : null;
		}

		//
		// IDocumentFileController
		//
		public final function attach(document:Document, reference:IFileReference):void
		{
			_file = reference as DesktopFileReference;
			_document = document;
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
		}

		protected function deactivate():void
		{
		}

		//
		// Properties
		//
		protected final function get file():DesktopFileReference { return _file; }
		protected final function get document():Document { return _document; }
	}
}