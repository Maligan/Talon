package talon.browser.platform.document.files
{
	import flash.events.IEventDispatcher;
	import flash.utils.ByteArray;

	[Event(type="flash.events.Event", name="change")]
	public interface IFileReference extends IEventDispatcher
	{
		/** - Relative path from source root.
		 *  - Unique identifier of file
		 *  - Separator - backslash (e.g. "/")
		 *  - Folder's path MUST end up with slash (e.g. "/") */
		function get path():String;

		/** - File's content
		 *  - Has "null" ONLY IF file not exist (if existence is unknown - empty ByteArray) */
		function get data():ByteArray;
	}
}