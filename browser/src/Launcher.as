package
{
	import browser.AppController;
	import browser.utils.Console;
	import browser.AppConstants;
	import browser.utils.DeviceProfile;
	import browser.utils.Storage;
	import browser.utils.registerClassAlias;

	import flash.desktop.ClipboardFormats;

	import flash.desktop.NativeApplication;
	import flash.desktop.NativeDragManager;
	import flash.display.MovieClip;
	import flash.display.NativeWindow;
	import flash.display.StageAlign;
	import flash.display.StageQuality;
	import flash.display.StageScaleMode;
	import flash.events.InvokeEvent;
	import flash.events.NativeDragEvent;
	import flash.filesystem.File;
	import flash.geom.Point;
	import flash.geom.Rectangle;

	import starling.core.Starling;
	import starling.display.Sprite;
	import starling.events.Event;

	import talon.Node;
	import talon.types.Gauge;

	[SWF(backgroundColor="#C7C7C7", frameRate="60")]
	public class Launcher extends MovieClip
	{
		private var _overlay:MovieClip;
		private var _controller:AppController;
		private var _invoke:String;

		public function Launcher()
		{
			stage ? initialize() : addEventListener(Event.ADDED_TO_STAGE, initialize);
		}

		private function initialize(e:* = null):void
		{
			removeEventListener(Event.ADDED_TO_STAGE, initialize);

			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.quality = StageQuality.BEST;
			stage.nativeWindow.minSize = new Point(200, 100);

			NativeApplication.nativeApplication.setAsDefaultApplication(AppConstants.DESIGNER_FILE_EXTENSION);
			NativeApplication.nativeApplication.addEventListener(InvokeEvent.INVOKE, onInvoke);

			// For native drag purpose
			_overlay = new MovieClip();
			addChild(_overlay);
			onResize(null);

			_controller = new AppController(this);
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
