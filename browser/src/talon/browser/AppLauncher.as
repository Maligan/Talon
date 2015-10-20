package talon.browser
{
	import flash.display.Loader;
	import flash.display.Sprite;

	import flash.desktop.NativeApplication;
	import flash.display.MovieClip;
	import flash.events.InvokeEvent;
	import flash.filesystem.File;
	import flash.net.URLRequest;
	import flash.system.ApplicationDomain;
	import flash.system.LoaderContext;

	import starling.events.Event;

	[SWF(frameRate="60")]
	public class AppLauncher extends MovieClip
	{
		private var _controller:AppPlatform;
		private var _plugins:int;
		private var _invoke:String;

		public function AppLauncher()
		{
			stage ? initialize() : addEventListener(Event.ADDED_TO_STAGE, initialize);
		}

		private function initialize(e:* = null):void
		{
			removeEventListener(Event.ADDED_TO_STAGE, initialize);

			NativeApplication.nativeApplication.addEventListener(InvokeEvent.INVOKE, onInvoke);
			// NativeApplication.nativeApplication.setAsDefaultApplication(AppConstants.DESIGNER_FILE_EXTENSION);

			// Create platform
			_controller = new AppPlatform(stage);
			_controller.settings.addPropertyListener(AppConstants.SETTING_BACKGROUND, onBackgroundColorChanged);

			initializePlugins();
		}

		private function initializePlugins():void
		{
			var dir:File = File.applicationDirectory.resolvePath(AppConstants.PLUGINS_DIR);
			if (dir.exists)
			{
				var files:Array = dir.getDirectoryListing();

				for each (var file:File in files)
				{
					if (file.extension == AppConstants.BROWSER_PLUGIN_EXTENSION)
					{
						_plugins++;

						var domain:ApplicationDomain = ApplicationDomain.currentDomain;
						var request:URLRequest = new URLRequest(file.url);
						var context:LoaderContext = new LoaderContext(false, domain);
						var loader:Loader = new Loader();
						loader.contentLoaderInfo.addEventListener(Event.COMPLETE, checkPlugins);
						loader.contentLoaderInfo.addEventListener(Event.IO_ERROR, checkPlugins);
						loader.contentLoaderInfo.addEventListener(Event.SECURITY_ERROR, checkPlugins);
						loader.load(request, context);
					}
				}
			}
		}

		private function checkPlugins(e:*):void
		{
			if (--_plugins == 0) _controller.initialize();
		}

		private function onInvoke(e:InvokeEvent):void
		{
			if (e.arguments.length > 0)
			{
				_invoke = e.arguments[0];
				_controller && _controller.invoke(_invoke);
			}
		}

		private function onBackgroundColorChanged():void
		{
			var colorName:String = _controller.settings.getValueOrDefault(AppConstants.SETTING_BACKGROUND, String, AppConstants.SETTING_BACKGROUND_DEFAULT);
			var color:uint = AppConstants.SETTING_BACKGROUND_STAGE_COLOR[colorName];
			stage.color = color;
		}
	}
}