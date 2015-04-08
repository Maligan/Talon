package browser.dom.assets
{
	import browser.dom.Document;
	import browser.dom.files.DocumentFileController;
	import browser.dom.files.DocumentFileReference;

	import starling.events.Event;

	internal class Asset implements DocumentFileController
	{
		private var _file:DocumentFileReference;

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