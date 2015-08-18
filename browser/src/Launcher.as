package
{
	import browser.AppConstants;
	import browser.AppController;

	import flash.desktop.NativeApplication;
	import flash.display.MovieClip;
	import flash.display.StageAlign;
	import flash.display.StageQuality;
	import flash.display.StageScaleMode;
	import flash.events.InvokeEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;

	import starling.events.Event;

	[SWF(frameRate="60")]
	public class Launcher extends MovieClip
	{
		private var _overlay:MovieClip;
		private var _controller:AppController;
		private var _invoke:String;
		private var _backgroundColor:SharedString;

		public function Launcher()
		{
			var source:String = "This is \\\\\\n new line";
			var target:String = source.replace(/[^\\](?:\\\\)?\\([nrt\s])/, replaceEscapedChars);

			trace(target);

			function replaceEscapedChars(match:String, char:String, offset:int, string:String):String
			{
				return match.replace("\\n", "\n");
			}

			_backgroundColor = new SharedString("backgroundColor", AppConstants.SETTING_BACKGROUND_DEFAULT);
			stage ? initialize() : addEventListener(Event.ADDED_TO_STAGE, initialize);
		}


		private function initialize(e:* = null):void
		{
			removeEventListener(Event.ADDED_TO_STAGE, initialize);

			stage.color = getColorByBackground(_backgroundColor.value);
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
			_controller.settings.addPropertyListener(AppConstants.SETTING_BACKGROUND, onBackgroundChanged);
		}

		private function onBackgroundChanged():void
		{
			_backgroundColor.value = _controller.settings.getValueOrDefault(AppConstants.SETTING_BACKGROUND, AppConstants.SETTING_BACKGROUND_DEFAULT);
		}

		private function getColorByBackground(key:String):uint
		{
			switch (key)
			{
				case AppConstants.SETTING_BACKGROUND_DARK:
					return 0x4A4D4E;
				case AppConstants.SETTING_BACKGROUND_LIGHT:
					return 0xFFFFFF;
				default:
					throw new ArgumentError("Unknown background key " + key);
			}
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

import flash.net.SharedObject;

class SharedString
{
	private var _sharedObject:SharedObject;

	public function SharedString(key:String, initial:String)
	{
		_sharedObject = SharedObject.getLocal(key);

		if (_sharedObject.data["value"] == undefined)
		{
			_sharedObject.data["value"] = initial;
		}
	}

	public function get value():String { return _sharedObject.data["value"]; }

	public function set value(string:String):void
	{
		try
		{
			_sharedObject.data["value"] = string;
			_sharedObject.flush();
		}
		catch (e:Error)
		{
			// NOPE
		}
	}
}