package browser.dom
{
	import browser.dom.assets.AtlasAsset;
	import browser.dom.assets.DirectoryAsset;
	import browser.dom.assets.FontAsset;
	import browser.dom.assets.TemplateAsset;
	import browser.dom.assets.StyleSheetAsset;
	import browser.dom.assets.TextureAsset;
	import browser.dom.files.DocumentFileReference;
	import browser.dom.files.DocumentFileReferenceCollection;
	import browser.dom.files.DocumentFileType;
	import browser.dom.log.DocumentMessageCollection;
	import browser.dom.log.DocumentTaskTracker;
	import browser.utils.Constants;

	import flash.filesystem.File;

	import flash.filesystem.File;

	import starling.events.Event;
	import starling.events.EventDispatcher;

	[Event(name="change", type="starling.events.Event")]
	public class Document extends EventDispatcher
	{
		private var _files:DocumentFileReferenceCollection;
		private var _factory:DocumentTalonFactory;
		private var _source:File;
		private var _document:File;
		private var _properties:Object;
		private var _messages:DocumentMessageCollection;
		private var _tracker:DocumentTaskTracker;

		public function Document(properties:Object):void
		{
			_tracker = new DocumentTaskTracker(onTasksEnd);
			_messages = new DocumentMessageCollection();

			_properties = properties;
			_factory = new DocumentTalonFactory(this);
			_files = new DocumentFileReferenceCollection(this);
			_files.registerDocumentFileType(DocumentFileType.DIRECTORY, DirectoryAsset);
			_files.registerDocumentFileType(DocumentFileType.IMAGE, TextureAsset);
			_files.registerDocumentFileType(DocumentFileType.TEMPLATE, TemplateAsset);
			_files.registerDocumentFileType(DocumentFileType.ATLAS, AtlasAsset);
			_files.registerDocumentFileType(DocumentFileType.STYLE, StyleSheetAsset);
			_files.registerDocumentFileType(DocumentFileType.FONT, FontAsset);
		}

		/** Background task counter. */
		public function get tasks():DocumentTaskTracker
		{
			return _tracker;
		}

		/** Document's files. */
		public function get files():DocumentFileReferenceCollection
		{
			return _files;
		}

		public function get factory():DocumentTalonFactory
		{
			return _factory;
		}

		public function get messages():DocumentMessageCollection
		{
			return _messages;
		}

		//
		// Update timer
		//
		private function onTasksEnd():void
		{
			dispatchEventWith(Event.CHANGE);
		}

		//
		// Export
		//
		public function get exportPath():String
		{
			var path:String = _properties[Constants.PROPERTY_EXPORT_PATH];
			var resolved:String = _document.parent ? _document.parent.resolvePath(path).nativePath : null;
			return resolved;
		}

		/** Get in export document file name. */
		public function getExportFileName(documentFile:DocumentFileReference):String
		{
			return _source.getRelativePath(documentFile.file);
		}

		public function setSourcePath(document:File, source:File):void
		{
			_document = document;
			_source = source;
		}
	}
}
