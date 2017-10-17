package talon.browser.core.document.files
{
	import talon.browser.core.document.Document;

	public class DummyFileController implements IFileController
	{
		public function attach(document:Document, reference:IFileReference):void { }
		public function detach():void { }
	}
}
