package browser.dom.assets
{
	import browser.dom.Document;
	import browser.dom.files.DocumentFileReference;

	public class AtlasAsset extends Asset
	{
		public function AtlasAsset()
		{
		}

		public override function initialize(document:Document, file:DocumentFileReference):void
		{
			super.initialize(document, file);
//			document.addEventListener(Event.CHANGE, onDocumentChange);
		}
	}
}
