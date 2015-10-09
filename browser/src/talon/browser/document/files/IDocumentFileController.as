package talon.browser.document.files
{
	public interface IDocumentFileController
	{
		/** @private For internal DocumentFileCollection usage only. */
		function setReference(reference:DocumentFileReference):void;

		function attach():void;
		function detach():void;
	}
}