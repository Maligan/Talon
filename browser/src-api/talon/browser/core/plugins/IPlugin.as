package talon.browser.core.plugins
{
	import talon.browser.core.App;

	public interface IPlugin
	{
		//
		// Info
		//
		/** Plugin unique id */
		function get id():String
		/** Plugin version in format: "MAJOR.MINOR.PATCH" */
		function get version():String
		/** Compatible browser API version in format: "MAJOR.MINOR.PATCH" */
		function get versionAPI():String

		//
		// Implementation
		//
		/** Attach plugin to application. */
		function attach(platform:App):void;
		/** Detach plugin to application. */
		function detach():void;
	}
}