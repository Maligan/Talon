package browser
{
	import browser.dom.DocumentEvent;
	import browser.dom.log.DocumentMessage;
	import browser.popups.Popup;
	import browser.utils.DeviceProfile;

	import flash.display.Stage;

	import flash.utils.ByteArray;

	import starling.core.Starling;
	import starling.display.DisplayObject;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.events.EventDispatcher;
	import starling.filters.BlurFilter;
	import starling.utils.HAlign;
	import starling.utils.VAlign;

	import talon.Attribute;
	import talon.layout.Layout;
	import talon.starling.TalonFactoryStarling;
	import talon.starling.TalonSprite;
	import talon.utils.TalonFactoryBase;

	public class AppUI extends EventDispatcher
	{
		[Embed(source="/../assets/interface.zip", mimeType="application/octet-stream")]
		private static const INTERFACE:Class;

		[Embed(source="/../assets/SourceSansPro.otf", embedAsCFF="false", fontName="Source Sans Pro")]
		private static const INTERFACE_FONT:Class;

//		[Embed(source="/../assets/LG.ttf", embedAsCFF="false", fontName="Lucida Grande")] private static const INTERFACE_FONT_1:Class;
//		[Embed(source="/../assets/LGB.ttf", embedAsCFF="false", fontName="Lucida Grande Bold")] private static const INTERFACE_FONT_2:Class;

		private var _controller:AppController;

		private var _factory:TalonFactoryBase;
		private var _interface:TalonSprite;
		private var _errorPage:TalonSprite;
		private var _isolatorContainer:TalonSprite;
		private var _isolator:Sprite;
		private var _container:TalonSprite;

		private var _template:DisplayObject;
		private var _templateProduceMessage:DocumentMessage;
		private var _locked:Boolean;

		public function AppUI(controller:AppController)
		{
			_controller = controller;
			_controller.addEventListener(AppController.EVENT_PROFILE_CHANGE, refreshWindowTitle);
			_controller.addEventListener(AppController.EVENT_PROTOTYPE_CHANGE, refreshCurrentTemplate);
			_controller.addEventListener(AppController.EVENT_DOCUMENT_CHANGE, onDocumentChanged);

			_controller.documentDispatcher.addEventListener(DocumentEvent.CHANGED, onDocumentChanged);
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

			Popup.initialize(this, _interface.getChildByName("popups") as TalonSprite);

			_container = new TalonSprite();
			_container.node.setAttribute(Attribute.LAYOUT, Layout.ABSOLUTE);
			_container.node.setAttribute(Attribute.VALIGN, VAlign.CENTER);
			_container.node.setAttribute(Attribute.HALIGN, HAlign.CENTER);
			_container.node.setAttribute(Attribute.ID, "IsolatedContainer");

			_isolator = new Sprite();
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

			resizeTo(_controller.root.stage.stageWidth, _controller.root.stage.stageHeight);

			dispatchEventWith(Event.COMPLETE);
		}

		private function onBackgroundChange(e:Event):void
		{
			var styleName:String = _controller.settings.getValueOrDefault(AppConstants.SETTING_BACKGROUND, AppConstants.SETTING_BACKGROUND_DEFAULT);
			_isolatorContainer.node.classes.parse(styleName);
		}

		private function onStatsChange(e:Event):void
		{
			Starling.current.showStats = _controller.settings.getValueOrDefault(AppConstants.SETTING_STATS, false);
		}

		private function onZoomChange(e:Event):void
		{
			zoom = _controller.settings.getValueOrDefault(AppConstants.SETTING_ZOOM, 100) / 100;
		}

		private function onAlwaysOnTopChange(e:Event):void
		{
			_controller.root.stage.nativeWindow.alwaysInFront = _controller.settings.getValueOrDefault(AppConstants.SETTING_ALWAYS_ON_TOP, false);
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

		private function onDocumentChanged(e:Event):void
		{
			refreshCurrentTemplate();
		}

		//
		// Refresh
		//
		private function refreshWindowTitle():void
		{
			var result:Array = [];

			if (_controller.document)
				result.push(_controller.document.project.nativePath);

			var profile:DeviceProfile = _controller.profile;
			if (profile != DeviceProfile.CUSTOM) result.push(_controller.profile.id);
			else result.push("[" + profile.width + "x" + profile.height + ", CSF=" + profile.csf + ", DPI=" + profile.dpi + "]");

			if (_controller.templateId)
				result.push(_controller.templateId);

			result.push(AppConstants.APP_NAME + " " + AppConstants.APP_VERSION);

			_controller.root.stage.nativeWindow.title = result.join(" - ");
		}

		private function refreshCurrentTemplate():void
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
				_templateProduceMessage = new DocumentMessage(DocumentMessage.PRODUCE_ERROR, [templateId, e.message]);
				_controller.document.messages.addMessage(_templateProduceMessage);
			}

			return result;
		}

		//
		// Properties
		//
		public function get factory():TalonFactoryBase { return _factory; }
		public function get template():DisplayObject { return _template; }

		public function get locked():Boolean { return _locked; }
		public function set locked(value:Boolean):void
		{
			if (_locked != value)
			{
				_locked = value;
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