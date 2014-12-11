package designer.dom.assets
{
	import designer.dom.Document;

	public class DocumentAsset
	{
		private var _document:Document;

		public function DocumentAsset(document:Document):void
		{
			_document = document;
		}

		/** Document which contain this asset. */
		public final function get document():Document { return _document; }

		/** Called once on asset added to document. */
		protected function include():void { }
		/** Called each time asset file(s) change. */
		protected function refresh():void { }
		/** Called once on asset removed from document. */
		protected function exclude():void { }
	}
}
