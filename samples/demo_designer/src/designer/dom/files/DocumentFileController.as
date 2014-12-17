package designer.dom.files
{
	import designer.dom.Document;

	public interface DocumentFileController
	{
		function initialize(document:Document, file:DocumentFileReference):void;
	}
}
