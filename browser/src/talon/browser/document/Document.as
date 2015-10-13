package talon.browser.document
{
	import talon.browser.document.files.DocumentFileReferenceCollection;
	import talon.browser.plugins.tools.types.XMLAtlasAsset;
	import talon.browser.plugins.tools.types.DirectoryAsset;
	import talon.browser.plugins.tools.types.XMLFontAsset;
	import talon.browser.plugins.tools.types.XMLLibraryAsset;
	import talon.browser.plugins.tools.types.PropertiesAsset;
	import talon.browser.plugins.tools.types.CSSAsset;
	import talon.browser.plugins.tools.types.XMLTemplateAsset;
	import talon.browser.plugins.tools.types.TextureAsset;
	import talon.browser.document.log.DocumentMessageCollection;
	import talon.browser.document.log.DocumentTaskTracker;
	import talon.browser.utils.Storage;
	import talon.browser.utils.TalonFeatherTextInput;

	import flash.filesystem.File;

	import starling.events.EventDispatcher;

	[Event(name="documentChanging", type="starling.events.Event")]
	[Event(name="documentChange",   type="starling.events.Event")]
	public class Document extends EventDispatcher
	{
		private var _project:File;

		/** This is parsed _project file content. */
		private var _properties:Storage;

		private var _files:DocumentFileReferenceCollection;
		private var _factory:DocumentTalonFactory;
		private var _messages:DocumentMessageCollection;
		private var _tracker:DocumentTaskTracker;
		private var _trackerIgnore:Boolean;

		public function Document(file:File)
		{
			_properties = Storage.fromPropertiesFile(file);
			_project = file;

			_files = new DocumentFileReferenceCollection(this);
			_tracker = new DocumentTaskTracker(onTasksEnd);
			_messages = new DocumentMessageCollection();
			_factory = new DocumentTalonFactory(this);
		}

		/** Background task counter. */
		public function get tasks():DocumentTaskTracker { return _tracker; }
		/** Document's files. */
		public function get files():DocumentFileReferenceCollection { return _files; }
		/** Talon factory. */
		public function get factory():DocumentTalonFactory { return _factory; }
		/** Status messages (aka Errors/Warnings/Infos). */
		public function get messages():DocumentMessageCollection { return _messages; }
		/** Document properties */
		public function get properties():Storage { return _properties; }
		/** @private Document files *.talon */
		public function get project():File { return _project; }

		public function dispose():void
		{
			removeEventListeners();
			files.dispose();
		}

		//
		// Update
		//
		private function onTasksEnd():void
		{
			if (_trackerIgnore === false)
			{
				_trackerIgnore = true;

				// For same assets
				dispatchEventWith(DocumentEvent.CHANGING);

				// After CHANGING, some file controllers may start new tasks
				if (!tasks.isBusy) dispatchEventWith(DocumentEvent.CHANGE);

				_trackerIgnore = false;
			}
		}
	}
}