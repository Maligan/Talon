package talon.browser.platform.plugins
{
	import talon.browser.platform.AppPlatform;

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
		function attach(platform:AppPlatform):void;
		/** Detach plugin to application. */
		function detach():void;
	}
}