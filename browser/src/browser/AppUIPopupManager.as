package browser
{
	import browser.popups.Popup;

	import starling.display.DisplayObjectContainer;

	public class AppUIPopupManager
	{
		private var _ui:AppUI;
		private var _layer:DisplayObjectContainer;

		private var _popups:Vector.<Popup>;

		public function initialize(ui:AppUI, layer:DisplayObjectContainer):void
		{
			_popups = new <Popup>[];
			_ui = ui;
			_layer = layer;
		}

		public function open(popup:Popup):void
		{
			if (_popups.indexOf(popup) == -1)
			{
				_popups.push(popup);
				_ui.locked = true;
				_layer.addChild(popup);
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
	}
}