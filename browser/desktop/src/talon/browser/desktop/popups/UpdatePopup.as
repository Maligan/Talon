package talon.browser.desktop.popups
{
	import flash.ui.Keyboard;
	import flash.ui.MouseCursor;

	import starling.display.DisplayObject;
	import starling.events.Event;

	import starling.utils.StringUtil;

	import talon.Attribute;
	import talon.browser.desktop.utils.Updater;
	import talon.browser.platform.popups.Popup;

	public class UpdatePopup extends Popup
	{
		private var _updater:Updater;

		protected override function initialize():void
		{
			addChild(manager.factory.createElement("UpdatePopup").self);
			node.commit();

			query("#cancel").onTap(onCancelClick);
			query("#update").onTap(onUpdateClick);
			query("#spinner").tween(1, { rotation: 2*Math.PI, repeatCount: 0 }, juggler);

			_updater = Updater(data);
			_updater.addEventListener(Event.CHANGE, onUpdaterChange);
			_updater.execute(true);

			addKeyboardListener(Keyboard.ENTER, onUpdateClick);
			addKeyboardListener(Keyboard.ESCAPE, onCancelClick);
		}

		public override function dispose():void
		{
			_updater.removeEventListener(Event.CHANGE, onUpdaterChange);
			super.dispose();
		}

		private function onUpdateClick(e:*):void
		{
			_updater.execute();
		}

		private function onCancelClick():void
		{
			_updater.stop();
			close();
		}

		private function onExpandClick(e:Event):void
		{
			var spinner:DisplayObject = e.target as DisplayObject;
			spinner.rotation = spinner.rotation == 0 ? -Math.PI/2 : 0;
		}

		//
		// Updater Events
		//
		private function onUpdaterChange(e:*):void
		{
			// [Begin load descriptor]
			if (_updater.step == 1)
			{
				query("#info").setAttribute(Attribute.TEXT, "$dialog.updater.patchLoading");
			}
			// [Begin load application]
			else if (_updater.step == 2)
			{
				query("#info").setAttribute(Attribute.TEXT, "[Загрузка приложения]");
			}
			// [Success descriptor load]
			else if (_updater.lastStatus == "UPDATE_DESCRIPTOR_LOADED")
			{
				var patchNotesPattern:String = node.getResource("dialog.updater.patchNotes");
				var patchNotes:String = StringUtil.format(patchNotesPattern, _updater.lastUpdaterVersion, _updater.lastUpdaterDescription.replace(/\t/g, ""));
				query("#info").setAttribute(Attribute.TEXT, patchNotes);
				// query("#spinner").setAttribute(Attribute.VISIBLE, false);

				query("#spinner")
					.setAttribute(Attribute.SOURCE, "$drop_down")
					.setAttribute(Attribute.MARGIN, "4px")
					.setAttribute(Attribute.CURSOR, MouseCursor.BUTTON)
					.onTap(onExpandClick)
					.tweenKill(juggler);
			}
			// [Success application load & start update]
			else if (_updater.lastStatus == "UPDATER_STARTED")
			{
			}
			// [Any exceptions]
			else
			{
				// Error
//				query("#info").setAttribute(Attribute.TEXT, _updater.lastStatus);
				query("#info").setAttribute(Attribute.TEXT, "Sorry, update can't be completed :-(");
				query("#info").setAttribute(Attribute.FONT_COLOR, "#FFaaaa");

				query("#spinner")
					.setAttribute(Attribute.SOURCE, "$drop_down")
					.setAttribute(Attribute.MARGIN, "4px")
					.setAttribute(Attribute.CURSOR, MouseCursor.BUTTON)
					.onTap(onExpandClick)
					.tweenKill(juggler);
			}

			node.invalidate();
			node.parent.parent.commit();
		}
	}
}
