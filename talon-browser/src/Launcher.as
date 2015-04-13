package
{
	import browser.utils.Constants;
	import browser.AppController;
	import browser.utils.Console;
	import browser.utils.DeviceProfile;
	import browser.utils.Settings;
	import browser.utils.parseGlob;

	import flash.desktop.NativeApplication;
	import flash.display.MovieClip;
	import flash.display.NativeWindow;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageQuality;
	import flash.display.StageScaleMode;
	import flash.events.InvokeEvent;
	import flash.geom.Rectangle;

	import starling.core.Starling;
	import starling.display.Sprite;
	import starling.events.Event;

	[SWF(backgroundColor="#C7C7C7", frameRate="60")]
	public class Launcher extends MovieClip
	{
		private var _controller:AppController;
		private var _console:Console;
		private var _invoke:String;

		public function Launcher()
		{
			stage.addEventListener(Event.RESIZE, onResize);
			stage.quality = StageQuality.BEST;
			adjust();

			// Add console
			addChild(_console = new Console());

			NativeApplication.nativeApplication.setAsDefaultApplication(Constants.DESIGNER_FILE_EXTENSION);
			NativeApplication.nativeApplication.addEventListener(InvokeEvent.INVOKE, onInvoke);

			new Starling(starling.display.Sprite, stage);
			Starling.current.addEventListener(Event.ROOT_CREATED, onRootCreated);
			Starling.current.start();

			onResize(null);
		}

		private function onResize(e:*):void
		{
			Starling.current.stage.stageWidth = stage.stageWidth;
			Starling.current.stage.stageHeight = stage.stageHeight;
			Starling.current.viewPort = new Rectangle(0, 0, stage.stageWidth, stage.stageHeight);

			_controller && _controller.resizeTo(stage.stageWidth, stage.stageHeight);
		}

		private function onRootCreated(e:*):void
		{
			_controller = new AppController(this, Starling.current.root as starling.display.Sprite, _console);
//			_invoke = _controller.settings.getValueOrDefault(Constants.SETTING_RECENT_ARRAY, [null])[0];
			_invoke && _controller.invoke(_invoke);
		}

		private function onInvoke(e:InvokeEvent):void
		{
			if (e.arguments.length > 0)
			{
				_invoke = e.arguments[0];
				_controller && _controller.invoke(_invoke);
			}
		}

		[Deprecated(message="Move from here to AppController")]
		private function adjust():void
		{
			var settings:Settings = new Settings("settings");
			var profileId:String = settings.getValueOrDefault(Constants.SETTING_PROFILE, null);
			var profile:DeviceProfile = DeviceProfile.getById(profileId) || DeviceProfile.CUSTOM;

			if (profile != DeviceProfile.CUSTOM)
			{
				var isPortrait:Boolean = settings.getValueOrDefault(Constants.SETTING_IS_PORTRAIT, false);
				var window:NativeWindow = root.stage.nativeWindow;
				var min:Number = Math.min(profile.width, profile.height);
				var max:Number = Math.max(profile.width, profile.height);

				if (isPortrait)
				{
					window.width = min;
					window.height = max;
				}
				else
				{
					window.width = max;
					window.height = min;
				}
			}
		}
	}
}