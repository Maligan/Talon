package talon.browser.desktop.popups
{
	import flash.events.Event;
	import flash.ui.Keyboard;
	import flash.utils.setTimeout;

	import starling.utils.StringUtil;

	import talon.Attribute;
	import talon.browser.desktop.utils.Updater;
	import talon.browser.platform.popups.Popup;

	public class UpdatePopup extends Popup
	{
		private var _updater:Updater;

		protected override function initialize():void
		{
			addChild(manager.factory.create("UpdatePopup"));
			node.commit();

			query("#cancel").onTap(onCancelClick);
			query("#update").onTap(onUpdateClick);
			query("#spinner").tween(1, { rotation: 2*Math.PI, repeatCount: 0 }, juggler);

			_updater = Updater(data);
			_updater.addEventListener(Event.CHANGE, onUpdaterChange);
			_updater.addEventListener(Event.COMPLETE, onUpdaterComplete);
			setTimeout(_updater.execute, 2000, true);

			addKeyboardListener(Keyboard.ENTER, onUpdateClick);
			addKeyboardListener(Keyboard.ESCAPE, onCancelClick);
		}

		public override function dispose():void
		{
			_updater.removeEventListener(Event.CHANGE, onUpdaterChange);
			_updater.removeEventListener(Event.COMPLETE, onUpdaterComplete);
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

		//
		// Updater Events
		//
		private function onUpdaterChange(e:*):void
		{
			// show Updater log
		}

		private function onUpdaterComplete(e:*):void
		{
			if (_updater.lastStatus == "UPDATE_DESCRIPTOR_LOADED")
			{
				var patchNotesPattern:String = node.getResource("dialog.updater.patchNotes");
				var patchNotes:String = StringUtil.format(patchNotesPattern, _updater.lastUpdaterVersion, _updater.lastUpdaterDescription.replace(/\t/g, ""));
				query("#info").setAttribute(Attribute.TEXT, patchNotes);
				query("#spinner").setAttribute(Attribute.VISIBLE, false);
			}
			else if (_updater.lastStatus == "UPDATER_STARTED")
			{

			}
			else // Error
			{
				query("#info").setAttribute(Attribute.TEXT, _updater.lastStatus);
				query("#spinner").setAttribute(Attribute.VISIBLE, false);
			}
		}
	}
}
