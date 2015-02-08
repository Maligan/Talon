package browser.dom.assets
{
	import browser.dom.files.DocumentFileReference;

	public class AtlasAsset extends Asset
	{
		public function AtlasAsset()
		{
		}

		public override function initialize(file:DocumentFileReference):void
		{
			super.initialize(file);
//			document.addEventListener(Event.CHANGE, onDocumentChange);
		}
	}
}
