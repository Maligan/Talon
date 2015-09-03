package browser.ui
{
	import browser.*;
	import browser.dom.DocumentEvent;
	import browser.dom.log.DocumentMessage;
	import browser.ui.popups.Popup;
	import browser.utils.DeviceProfile;

	import flash.display.Stage;

	import flash.utils.ByteArray;
	import flash.utils.setTimeout;

	import starling.core.Starling;
	import starling.display.DisplayObject;
	import starling.display.DisplayObjectContainer;
	import starling.display.Sprite;
	import starling.display.Sprite3D;
	import starling.events.Event;
	import starling.events.EventDispatcher;
	import starling.filters.BlurFilter;
	import starling.utils.HAlign;
	import starling.utils.VAlign;

	import talon.Attribute;
	import talon.layout.Layout;
	import talon.starling.TalonFactoryStarling;
	import talon.starling.TalonSprite;
	import talon.utils.ITalonElement;
	import talon.utils.TalonFactoryBase;

	public class AppUI extends EventDispatcher
	{
		[Embed(source="/../assets/interface.zip", mimeType="application/octet-stream")] private static const INTERFACE:Class;
		[Embed(source="/../assets/SourceSansPro.otf", embedAsCFF="false", fontName="Source Sans Pro")] private static const INTERFACE_FONT:Class;

		private var _controller:AppController;
		private var _menu:AppUINativeMenu;
		private var _popups:AppUIPopupManager;

		private var _factory:TalonFactoryBase;
		private var _interface:TalonSprite;
		private var _errorPage:TalonSprite;
		private var _isolatorContainer:TalonSprite;
		private var _isolator:DisplayObjectContainer;
		private var _container:TalonSprite;

		private var _template:DisplayObject;
		private var _templateProduceMessage:DocumentMessage;
		private var _locked:Boolean;

		public function AppUI(controller:AppController)
		{
			_controller = controller;
			_controller.addEventListener(AppController.EVENT_TEMPLATE_CHANGE, refreshWindowTitle);
			_controller.addEventListener(AppController.EVENT_TEMPLATE_CHANGE, refreshCurrentTemplate);
			_controller.addEventListener(AppController.EVENT_DOCUMENT_CHANGE, refreshCurrentTemplate);
			_controller.documentDispatcher.addEventListener(DocumentEvent.CHANGED, refreshCurrentTemplate);

			_controller.profile.addEventListener(Event.CHANGE, refreshWindowTitle);

			_isolator = new Sprite();
			_menu = new AppUINativeMenu(_controller);
			_popups = new AppUIPopupManager();
		}

		/** Call after starling initialize completed. */
		public function initialize():void
		{
			_factory = new TalonFactoryStarling();
			_factory.setLinkage("interface", TalonSpriteWithDrawCountReset);
			_factory.addArchiveContentAsync(new INTERFACE() as ByteArray, onFactoryComplete);
		}

		//
		// Logic
		//
		private function onFactoryComplete():void
		{
			_interface = _factory.produce("interface") as TalonSprite;
			_controller.host.addChild(_interface);

			_popups.initialize(this, _interface.getChildByName("popups") as DisplayObjectContainer);

			_container = new TalonSprite();
			_container.node.setAttribute(Attribute.LAYOUT, Layout.FLOW);
			_container.node.setAttribute(Attribute.VALIGN, VAlign.CENTER);
			_container.node.setAttribute(Attribute.HALIGN, HAlign.CENTER);
			_container.node.setAttribute(Attribute.ID, "IsolatedContainer");

			_isolator.alignPivot();
			_isolator.name = "Isolator";
			_isolator.addChild(_container);

			_errorPage = _interface.getChildByName("bsod") as TalonSprite;
			_errorPage.visible = false;

			_isolatorContainer = _interface.getChildByName("container") as TalonSprite;
			_isolatorContainer.addChild(_isolator);

			_controller.settings.addPropertyListener(AppConstants.SETTING_BACKGROUND, onBackgroundChange); onBackgroundChange(null);
			_controller.settings.addPropertyListener(AppConstants.SETTING_STATS, onStatsChange); onStatsChange(null);
			_controller.settings.addPropertyListener(AppConstants.SETTING_ZOOM, onZoomChange); onZoomChange(null);
			_controller.settings.addPropertyListener(AppConstants.SETTING_ALWAYS_ON_TOP, onAlwaysOnTopChange); onAlwaysOnTopChange(null);
			_controller.monitor.addEventListener(Event.CHANGE, refreshCurrentTemplate);

			resizeTo(_controller.root.stage.stageWidth, _controller.root.stage.stageHeight);

			dispatchEventWith(Event.COMPLETE);
		}

		private function onBackgroundChange(e:Event):void
		{
			var styleName:String = _controller.settings.getValueOrDefault(AppConstants.SETTING_BACKGROUND, String, AppConstants.SETTING_BACKGROUND_DEFAULT);
			_interface.node.classes.parse(styleName);
			_controller.root.stage.color = AppConstants.SETTING_BACKGROUND_STAGE_COLOR[styleName];
		}

		private function onStatsChange(e:Event):void
		{
			Starling.current.showStats = _controller.settings.getValueOrDefault(AppConstants.SETTING_STATS, Boolean, false);
		}

		private function onZoomChange(e:Event):void
		{
			zoom = _controller.settings.getValueOrDefault(AppConstants.SETTING_ZOOM, int, 100) / 100;
			refreshWindowTitle();
		}

		private function onAlwaysOnTopChange(e:Event):void
		{
			_controller.root.stage.nativeWindow.alwaysInFront = _controller.settings.getValueOrDefault(AppConstants.SETTING_ALWAYS_ON_TOP, Boolean, false);
		}

		public function resizeTo(width:int, height:int):void
		{
			if (_interface && (_interface.node.bounds.width != width || _interface.node.bounds.height != height))
			{
				_interface.node.bounds.setTo(0, 0, width, height);
				_interface.node.invalidate();
			}

			if (_container)
			{
				_container.node.bounds.setTo(0, 0, width/zoom, height/zoom);
				_container.node.invalidate();
			}
		}

		//
		// Refresh
		//
		private function refreshWindowTitle():void
		{
			var result:Array = [];

			// Open document/template
			if (_controller.document)
			{
				var title:String = _controller.document.project.name.replace(/\.[^\.]*$/,"");
				if (_controller.templateId) title += "/" + _controller.templateId;
				result.push(title);
			}

			var profile:DeviceProfile = _controller.profile;
			var profileEqual:DeviceProfile = DeviceProfile.getEqual(profile);
			var profileName:String = profileEqual ? profileEqual.id : null;

			// Profile preference
			result.push("[" + profile.width + "x" + profile.height + ", CSF=" + profile.csf + ", DPI=" + profile.dpi + "]");
			// Profile name (if exist)
			if (profileName) result.push(profileName);
			// Zoom (if non 100%)
			if (zoom != 1) result.push(int(zoom * 100) + "%");
			// Application name + version
			result.push(AppConstants.APP_NAME + " " + AppConstants.APP_VERSION.replace(/\.0$/, ""));

			_controller.root.stage.nativeWindow.title = result.join(" - ");
		}

		private function refreshCurrentTemplate(e:* = null):void
		{
			// Refresh current prototype
			var canShow:Boolean = true;
			canShow &&= _controller.templateId != null;
			canShow &&= _controller.document != null;
			canShow &&= _controller.document.tasks.isBusy == false;
			canShow &&= _controller.document.factory.hasTemplate(_controller.templateId);

			_errorPage.visible = false;
			_container.removeChildren();
			_controller.document && _controller.document.messages.removeMessage(_templateProduceMessage);
			_templateProduceMessage = null;

			_template && _template.removeFromParent(true);
			_template = canShow ? produce(_controller.templateId) : null;

			// Show state
			if (_controller.document && _controller.document.messages.numMessages != 0)
			{
				_errorPage.visible = true;
			}
			else if (_template != null)
			{
				_container.node.ppmm = ITalonElement(_template).node.ppmm;
				_container.node.ppdp = ITalonElement(_template).node.ppdp;
				_container.addChild(_template);
				_controller.root.stage && resizeTo(_controller.root.stage.stageWidth, _controller.root.stage.stageHeight);
			}
		}

		private function produce(templateId:String):DisplayObject
		{
			var result:DisplayObject = null;

			try
			{
				result = _controller.document.factory.produce(templateId);
			}
			catch (e:Error)
			{
				_templateProduceMessage = new DocumentMessage(DocumentMessage.PRODUCE_ERROR, [templateId, e.getStackTrace()]);
				_controller.document.messages.addMessage(_templateProduceMessage);
			}

			return result;
		}

		//
		// Drag&Drop
		//

		//
		// Properties
		//
		public function get popups():AppUIPopupManager { return _popups; }

		public function get factory():TalonFactoryBase { return _factory; }
		public function get template():DisplayObject { return _template; }

		public function get locked():Boolean { return _locked; }
		public function set locked(value:Boolean):void
		{
			if (_locked != value)
			{
				_locked = value;
				_menu.locked = !value;
				_isolatorContainer.filter = _locked ? new BlurFilter(1, 1) : null;
				_isolatorContainer.touchable = !_locked;
			}
		}

		public function get zoom():Number { return _isolator.scaleX; }
		public function set zoom(value:Number):void
		{
			if (zoom != value)
			{
				_isolator.scaleX = _isolator.scaleY = value;
				resizeTo(_controller.root.stage.stageWidth, _controller.root.stage.stageHeight);
			}
		}
	}
}

import starling.core.RenderSupport;

import talon.starling.TalonSprite;

class TalonSpriteWithDrawCountReset extends TalonSprite
{
	public override function render(support:RenderSupport, parentAlpha:Number):void
	{
		super.render(support, parentAlpha);
		support.raiseDrawCount(-1);
	}
}