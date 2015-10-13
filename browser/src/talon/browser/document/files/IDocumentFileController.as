package talon.browser.document.files
{
	public interface IDocumentFileController
	{
		function attach(reference:DocumentFileReference):void;
		function detach():void;
	}
}