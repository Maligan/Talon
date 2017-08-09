package talon.browser.platform.utils
{
	import starling.display.*;

	public class DisplayTreeUtil
	{
		public static function findChildByName(root:DisplayObjectContainer, name:String):DisplayObject
		{
			var i:int = 0;
			var child:DisplayObject = null;
			var childAsContainer:DisplayObjectContainer = null;

			for (i = 0; i < root.numChildren; i++)
			{
				child = root.getChildAt(i);
				if (child.name == name) return child;
			}

			for (i = 0; i < root.numChildren; i++)
			{
				childAsContainer = root.getChildAt(i) as DisplayObjectContainer;

				if (childAsContainer)
				{
					var descendant:DisplayObject = findChildByName(childAsContainer, name);
					if (descendant) return descendant;
				}
			}

			return null;
		}
	}
}