package talon.browser
{
	import talon.browser.utils.FuzzyUtil;

	import flash.desktop.NativeApplication;
	import flash.display.MovieClip;
	import flash.events.InvokeEvent;
	import flash.geom.Point;
	import flash.utils.getTimer;

	import starling.events.Event;

	import talon.utils.StringUtil;

	[SWF(frameRate="60")]
	public class AppLauncher extends MovieClip
	{
		private var _overlay:MovieClip;
		private var _controller:AppController;
		private var _invoke:String;
		private var _backgroundColor:SharedString;

		public function AppLauncher()
		{
			_backgroundColor = new SharedString("backgroundColor", AppConstants.SETTING_BACKGROUND_DEFAULT);
			stage ? initialize() : addEventListener(Event.ADDED_TO_STAGE, initialize);
		}

		private function initialize(e:* = null):void
		{
			removeEventListener(Event.ADDED_TO_STAGE, initialize);

			NativeApplication.nativeApplication.addEventListener(InvokeEvent.INVOKE, onInvoke);
			//NativeApplication.nativeApplication.setAsDefaultApplication(AppConstants.DESIGNER_FILE_EXTENSION);

			stage.color = AppConstants.SETTING_BACKGROUND_STAGE_COLOR[_backgroundColor.value];
			stage.nativeWindow.minSize = new Point(200, 100);
			stage.addEventListener(Event.RESIZE, onResize);

			// For native drag purpose
			_overlay = new MovieClip();
			addChild(_overlay);
			onResize(null);

			_controller = new AppController(this);
			_controller.settings.addPropertyListener(AppConstants.SETTING_BACKGROUND, onBackgroundChanged);
		}

		private function onBackgroundChanged():void
		{
			_backgroundColor.value = _controller.settings.getValueOrDefault(AppConstants.SETTING_BACKGROUND, String, AppConstants.SETTING_BACKGROUND_DEFAULT);
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
