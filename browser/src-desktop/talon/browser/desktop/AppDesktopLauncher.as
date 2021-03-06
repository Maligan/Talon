package talon.browser.desktop
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

	import talon.browser.desktop.plugins.PluginConsole;
	import talon.browser.desktop.plugins.PluginDesktopDragAndDrop;
	import talon.browser.desktop.plugins.PluginDesktop;
	import talon.browser.desktop.plugins.PluginFileType;
	import talon.browser.core.AppConstants;
	import talon.browser.core.App;
	import talon.browser.core.AppEvent;

	[SWF(frameRate="60")]
	public class AppDesktopLauncher extends Sprite
	{
		private var _platform:App; 
		private var _numPluginLoaders:int;

		public function AppDesktopLauncher()
		{
			stage ? initialize() : addEventListener(Event.ADDED_TO_STAGE, initialize);
		}

		private function initialize(e:* = null):void
		{
			removeEventListener(Event.ADDED_TO_STAGE, initialize);

			NativeApplication.nativeApplication.addEventListener(InvokeEvent.INVOKE, onInvoke);
			
			// Create app root class
			_platform = new App(stage);
			_platform.addEventListener(AppEvent.ERROR, onFatalError);
			_platform.addEventListener(AppEvent.STARTED, onStarted);

			_platform.settings

			// Search for modules, and start app class
			loadPluginsAndStartPlatform();
		}

		private function loadPluginsAndStartPlatform():void
		{
			// Register built-in plugins
			PluginConsole;
			PluginFileType;
			PluginDesktopDragAndDrop;
			PluginDesktop;
			
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

				loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, onPluginLoaded);
				loader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, onPluginLoaded);
				loader.contentLoaderInfo.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onPluginLoaded);

				// Import all classes from SWF which implements 'IPlugin' interface
				_platform.plugins.addPluginsFromApplicationDomain(domain);

				// Success load or not - it does not matter
				checkStart();
			}
		}

		private function checkStart():void
		{
			if (_numPluginLoaders == 0)
				_platform.start();
		}

		private function onStarted(e:*):void
		{
			// Make visible & focus
			stage.nativeWindow.activate();
		}

		private function onInvoke(e:InvokeEvent):void
		{
			if (e.arguments.length > 0)
				_platform.invoke(e.arguments);
		}

		private function onFatalError(e:*):void
		{
			var message:String = e.data;
			if (message == null) message = "Internal fatal error";
			_platform.starling.stopWithFatalError(message);
		}
	}
}