package talon.browser
{
	import flash.display.Sprite;

	import flash.desktop.NativeApplication;
	import flash.display.MovieClip;
	import flash.events.InvokeEvent;
	import flash.geom.Point;

	import starling.events.Event;

	[SWF(frameRate="60")]
	public class AppLauncher extends MovieClip
	{
		private var _overlay:Sprite;
		private var _controller:AppController;
		private var _invoke:String;

		public function AppLauncher()
		{
			if (stage) initialize();
			else addEventListener(Event.ADDED_TO_STAGE, initialize);
		}

		private function initialize(e:* = null):void
		{
			removeEventListener(Event.ADDED_TO_STAGE, initialize);

			NativeApplication.nativeApplication.addEventListener(InvokeEvent.INVOKE, onInvoke);
			//NativeApplication.nativeApplication.setAsDefaultApplication(AppConstants.DESIGNER_FILE_EXTENSION);

			stage.nativeWindow.minSize = new Point(200, 100);
			stage.addEventListener(Event.RESIZE, onResize);

			// For native drag purpose
			_overlay = new Sprite();
			addChild(_overlay);
			onResize(null);

			_controller = new AppController(this);
			_controller.settings.addPropertyListener(AppConstants.SETTING_BACKGROUND, onBackgroundColorChanged);
		}

		private function onBackgroundColorChanged():void
		{
			var colorName:String = _controller.settings.getValueOrDefault(AppConstants.SETTING_BACKGROUND, String, AppConstants.SETTING_BACKGROUND_DEFAULT);
			var color:uint = AppConstants.SETTING_BACKGROUND_STAGE_COLOR[colorName];
			stage.color = color;
		}

		private function onResize(e:*):void
		{
			_overlay.graphics.clear();
			_overlay.graphics.beginFill(0, 0);
			_overlay.graphics.drawRect(0, 0, stage.stageWidth, stage.stageHeight);
			_overlay.graphics.endFill();
		}

		private function onInvoke(e:InvokeEvent):void
		{
			if (e.arguments.length > 0)
			{
				_invoke = e.arguments[0];
				_controller && _controller.invoke(_invoke);
			}
		}
	}
}