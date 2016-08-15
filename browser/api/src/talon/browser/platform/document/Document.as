package talon.browser.platform.document
{
	import starling.events.EventDispatcher;

	import talon.browser.platform.document.files.DocumentFileCollection;
	import talon.browser.platform.document.log.DocumentMessageCollection;
	import talon.browser.platform.document.log.DocumentTaskTracker;

	import talon.browser.platform.utils.Storage;

	[Event(name="documentChanging", type="starling.events.Event")]
	[Event(name="documentChange",   type="starling.events.Event")]
	public class Document extends EventDispatcher
	{
		private var _properties:Storage;
		private var _files:DocumentFileCollection;
		private var _factory:DocumentTalonFactory;
		private var _messages:DocumentMessageCollection;
		private var _tracker:DocumentTaskTracker;
		private var _trackerIgnore:Boolean;

		public function Document(properties:Storage)
		{
			_properties = properties;
			_files = new DocumentFileCollection(this);
			_tracker = new DocumentTaskTracker(onTasksEnd);
			_messages = new DocumentMessageCollection();
			_factory = new DocumentTalonFactory(this);
		}

		/** Background task counter. */
		public function get tasks():DocumentTaskTracker { return _tracker; }
		/** Document's files. */
		public function get files():DocumentFileCollection { return _files; }
		/** Talon factory. */
		public function get factory():DocumentTalonFactory { return _factory; }
		/** Status messages (aka Errors/Warnings/Infos). */
		public function get messages():DocumentMessageCollection { return _messages; }
		/** Document properties */
		public function get properties():Storage { return _properties; }

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