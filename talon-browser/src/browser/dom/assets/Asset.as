package browser.dom.assets
{
	import browser.dom.Document;
	import browser.dom.files.DocumentFileController;
	import browser.dom.files.DocumentFileReference;

	import starling.events.Event;

	internal class Asset implements DocumentFileController
	{
		private var _document:Document;
		private var _file:DocumentFileReference;

		public function initialize(document:Document, file:DocumentFileReference):void
		{
			_document = document;
			_file = file;
			_file.addEventListener(Event.CHANGE, onFileChange);

			onInclude();
			onRefresh();
		}

		private function onFileChange(e:Event):void
		{
			_file.exits ? onRefresh() : onExclude();
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
			return _document;
		}

		protected function get file():DocumentFileReference
		{
			return _file;
		}
	}
}