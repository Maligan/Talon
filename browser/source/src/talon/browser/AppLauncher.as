package talon.browser
{
	import flash.desktop.NativeApplication;
	import flash.display.Loader;
	import flash.display.Sprite;
	import flash.events.InvokeEvent;
	import flash.filesystem.File;
	import flash.net.URLRequest;
	import flash.system.ApplicationDomain;
	import flash.system.LoaderContext;

	import starling.events.Event;

	[SWF(frameRate="60")]
	public class AppLauncher extends Sprite
	{
		private var _platform:AppPlatform;
		private var _numPlugins:int;

		public function AppLauncher()
		{
			stage ? initialize() : addEventListener(Event.ADDED_TO_STAGE, initialize);
		}

		private function initialize(e:* = null):void
		{
			removeEventListener(Event.ADDED_TO_STAGE, initialize);

			NativeApplication.nativeApplication.addEventListener(InvokeEvent.INVOKE, onInvoke);
			// NativeApplication.nativeApplication.setAsDefaultApplication(AppConstants.DESIGNER_FILE_EXTENSION);

			// Create platform root class
			_platform = new AppPlatform(stage);

			// Search for modules, and start platform class
			loadPluginsAndStart();
		}

		private function loadPluginsAndStart():void
		{
			var dir:File = File.applicationDirectory.resolvePath(AppConstants.PLUGINS_DIR);
			if (dir.exists)
			{
				var files:Array = dir.getDirectoryListing();

				for each (var file:File in files)
					if (file.extension == AppConstants.BROWSER_PLUGIN_EXTENSION)
						loadPlugin(file.url);
			}

			startCheck();
		}

		private function loadPlugin(url:String):void
		{
			_numPlugins++;

			var domain:ApplicationDomain = ApplicationDomain.currentDomain;
			var request:URLRequest = new URLRequest(url);
			var context:LoaderContext = new LoaderContext(false, domain);
			var loader:Loader = new Loader();
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onPluginLoaded);
			loader.contentLoaderInfo.addEventListener(Event.IO_ERROR, onPluginLoaded);
			loader.contentLoaderInfo.addEventListener(Event.SECURITY_ERROR, onPluginLoaded);
			loader.load(request, context);
		}

		private function onPluginLoaded(e:*):void
		{
			_numPlugins--;

			// Success load or not - it does not matter
			startCheck();
		}

		private function startCheck():void
		{
			if (_numPlugins == 0)
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