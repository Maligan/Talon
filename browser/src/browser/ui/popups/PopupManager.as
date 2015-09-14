package browser.ui.popups
{
	import browser.ui.*;
	import browser.ui.popups.Popup;

	import starling.display.DisplayObjectContainer;

	import talon.starling.TalonFactoryStarling;

	public class PopupManager
	{
		private var _ui:AppUI;
		private var _layer:DisplayObjectContainer;
		private var _factory:TalonFactoryStarling;
		private var _popups:Vector.<Popup>;

		public function initialize(ui:AppUI, layer:DisplayObjectContainer, factory:TalonFactoryStarling):void
		{
			_popups = new <Popup>[];
			_ui = ui;
			_layer = layer;
			_factory = factory;
		}

		public function open(popup:Popup):void
		{
			if (_popups.indexOf(popup) == -1)
			{
				_popups.push(popup);
				_ui.locked = true;
				_layer.addChild(popup);
				popup.initialize(this);
			}
		}

		public function close(popup:Popup):void
		{
			var indexOf:int = _popups.indexOf(popup);
			if (indexOf != -1)
			{
				_popups.splice(indexOf, 1);
				_layer.removeChild(popup);
				_ui.locked = _popups.length>0;
			}
		}

		public function get factory():TalonFactoryStarling
		{
			return _factory;
		}
	}
}