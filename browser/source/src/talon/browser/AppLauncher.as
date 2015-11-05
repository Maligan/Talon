package talon.browser
{
	import flash.desktop.NativeApplication;
	import flash.display.Loader;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.InvokeEvent;
	import flash.events.SecurityErrorEvent;
	import flash.filesystem.File;
	import flash.net.URLRequest;
	import flash.system.ApplicationDomain;
	import flash.system.LoaderContext;

	import talon.browser.plugins.tools.CorePluginConsole;
	import talon.browser.plugins.tools.CorePluginDragAndDrop;
	import talon.browser.plugins.tools.CorePluginFileType;

	[SWF(frameRate="60")]
	public class AppLauncher extends Sprite
	{
		private var _platform:AppPlatform;
		private var _numPluginLoaders:int;

		public function AppLauncher()
		{
			stage ? initialize() : addEventListener(Event.ADDED_TO_STAGE, initialize);
		}

		private function initialize(e:* = null):void
		{
			removeEventListener(Event.ADDED_TO_STAGE, initialize);

			NativeApplication.nativeApplication.addEventListener(InvokeEvent.INVOKE, onInvoke);
			NativeApplication.nativeApplication.setAsDefaultApplication(AppConstants.BROWSER_DOCUMENT_EXTENSION);

			// Create platform root class
			_platform = new AppPlatform(stage);

			// Search for modules, and start platform class
			loadPluginsAndStartPlatform();
		}

		private function loadPluginsAndStartPlatform():void
		{
			// Register built-in plugins
			CorePluginConsole;
			CorePluginFileType;
			CorePluginDragAndDrop;
			_platform.plugins.addPluginsFromApplicationDomain(ApplicationDomain.currentDomain);

			// Search plugins in application subdirectory
			var dir:File = File.applicationDirectory.resolvePath(AppConstants.PLUGINS_DIR);
			if (dir.exists)
			{
				var files:Array = dir.getDirectoryListing();

				for each (var file:File in files)
					if (file.extension == AppConstants.BROWSER_PLUGIN_EXTENSION)
						loadPlugin(file.url);
			}

			// Check plugin loading status
			checkStart();
		}

		private function loadPlugin(url:String):void
		{
			_numPluginLoaders++;

			var domain:ApplicationDomain = new ApplicationDomain(ApplicationDomain.currentDomain);
			var request:URLRequest = new URLRequest(url);
			var context:LoaderContext = new LoaderContext(false, domain);
			var loader:Loader = new Loader();
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onPluginLoaded);
			loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onPluginLoaded);
			loader.contentLoaderInfo.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onPluginLoaded);
			loader.load(request, context);

			function onPluginLoaded(e:Event):void
			{
				_numPluginLoaders--;

				// Import all classes from SWF which implements 'IPlugin' interface
				_platform.plugins.addPluginsFromApplicationDomain(domain);

				loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, onPluginLoaded);
				loader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, onPluginLoaded);
				loader.contentLoaderInfo.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onPluginLoaded);

				// Success load or not - it does not matter
				checkStart();
			}
		}

		private function checkStart():void
		{
			if (_numPluginLoaders == 0)
				_platform.start();
		}

		private function onInvoke(e:InvokeEvent):void
		{
			if (e.arguments.length > 0)
			{
				_platform.invoke(e.arguments);
			}
		}
	}
}